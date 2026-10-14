extends Node3D
## Main level: Uncle Oli save points, zone atmosphere, HUD, pause and ending.
## With cinematic = true the scene is only a backdrop (menu and story).

const MENU_SCENE := 'res://Scenes/main_menu.tscn'
const ZONE_LOOKS := [
	{ # Floating Town: clear sky above Earth
		'sky_top': Color(0.18, 0.46, 0.84), 'horizon': Color(0.74, 0.87, 0.98),
		'ground_horizon': Color(0.72, 0.84, 0.9), 'ground_bottom': Color(0.32, 0.48, 0.36),
		'fog': Color(0.76, 0.87, 0.97), 'fog_density': 0.0025,
		'ambient': Color(0.82, 0.9, 1.0), 'ambient_energy': 0.75,
		'sun': Color(1.0, 0.97, 0.9), 'sun_energy': 1.25, 'stars': 0.0,
	},
	{ # Cloud Sea: warm sunset above the clouds
		'sky_top': Color(0.42, 0.36, 0.78), 'horizon': Color(1.0, 0.74, 0.62),
		'ground_horizon': Color(1.0, 0.86, 0.8), 'ground_bottom': Color(0.96, 0.92, 0.96),
		'fog': Color(1.0, 0.86, 0.84), 'fog_density': 0.0032,
		'ambient': Color(1.0, 0.84, 0.86), 'ambient_energy': 0.85,
		'sun': Color(1.0, 0.78, 0.55), 'sun_energy': 1.15, 'stars': 0.15,
	},
	{ # Space Top: dark sky full of stars
		'sky_top': Color(0.01, 0.01, 0.04), 'horizon': Color(0.1, 0.05, 0.22),
		'ground_horizon': Color(0.07, 0.03, 0.16), 'ground_bottom': Color(0.0, 0.0, 0.02),
		'fog': Color(0.05, 0.03, 0.12), 'fog_density': 0.0,
		'ambient': Color(0.55, 0.6, 0.95), 'ambient_energy': 0.6,
		'sun': Color(0.86, 0.9, 1.0), 'sun_energy': 1.45, 'stars': 1.0,
	},
]
const KEEPER_LINES := '"เจ้าไม่มีพลังพิเศษใด ๆ เลย แต่ก็ปีนมาถึงที่นี่ได้ด้วยความมุ่งมั่นล้วน ๆ\nดาวแห่งความปรารถนาเป็นของเจ้าแล้ว Aof ขอสิ่งที่เจ้าต้องการได้หนึ่งข้อ..."'

@export var cinematic: bool = false
@onready var checkpoints: Node3D = $Checkpoints
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
var player: CharacterBody3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var star_material: StandardMaterial3D
var star_field: GeometryInstance3D
var space_scenery: Node3D
var earth_visuals: Array[Node3D] = []
var zone_heights: Array = [0.0]
var zone_names: Array = ['']
var summit_height: float = 100.0
var active_checkpoint: int = 0
var respawn_position := Vector3.ZERO
var falls: int = 0
var foods_eaten: int = 0
var elapsed: float = 0.0
var best_height: float = 0.0
var finished: bool = false
var shown_zone: int = 0
# HUD
var hud: CanvasLayer
var boost_row: Control
var boost_bar: ProgressBar
var admin_label: Label
var dialog: PanelContainer
var dialog_name: Label
var dialog_text: Label
var dialog_time: float = 0.0
var toast: Label
var toast_time: float = 0.0
var zone_title: Label
var zone_title_time: float = 0.0
var pause_overlay: Control
var popup: Control

func _ready() -> void:
	add_to_group('Level')
	zone_heights = get_meta('zone_heights', [0.0])
	zone_names = get_meta('zone_names', [''])
	summit_height = get_meta('summit_height', 100.0)
	environment = world_environment.environment
	sky_material = environment.sky.sky_material
	star_field = get_node_or_null('Decor/StarField')
	space_scenery = get_node_or_null('Decor/SpaceScenery')
	for path in ['Earth/Ground', 'Decor/Skyline', 'Decor/FloatingIslands']:
		if has_node(path):
			earth_visuals.append(get_node(path))
	if star_field:
		star_material = star_field.material_override
	player = get_node_or_null('Player')
	if cinematic:
		if player:
			remove_child(player)
			player.free()
			player = null
		apply_look(0.0)
		return
	var first: Area3D = checkpoints.get_child(0)
	respawn_position = first.get_node('Spawn').global_position
	first.set_active(true)
	if not InputMap.has_action('return_checkpoint'):
		InputMap.add_action('return_checkpoint')
		var key := InputEventKey.new()
		key.physical_keycode = KEY_R
		InputMap.action_add_event('return_checkpoint', key)
	if not InputMap.has_action('admin_noclip'):
		InputMap.add_action('admin_noclip')
		var insert := InputEventKey.new()
		insert.physical_keycode = KEY_INSERT
		InputMap.action_add_event('admin_noclip', insert)
	build_hud()
	var save: Dictionary = GameManager.take_continue()
	if save.is_empty():
		show_zone_title(0)
		say('ลุงโอลี่', first.message, 9.0)
	else:
		resume_from(save)
	apply_look(player.global_position.y)

## Continue: start at the saved Uncle Oli save point with the saved stats.
func resume_from(save: Dictionary) -> void:
	var index := clampi(int(save.get('checkpoint', 0)), 0, checkpoints.get_child_count() - 1)
	checkpoints.get_child(0).set_active(false)
	var checkpoint: Area3D = checkpoints.get_child(index)
	active_checkpoint = index
	respawn_position = checkpoint.get_node('Spawn').global_position
	checkpoint.set_active(true)
	elapsed = float(save.get('elapsed', 0.0))
	falls = int(save.get('falls', 0))
	foods_eaten = int(save.get('foods', 0))
	shown_zone = index
	player.reset_to_spawn(respawn_position)
	show_zone_title(index)
	say('ลุงโอลี่', 'ยินดีต้อนรับกลับมา Aof! ไปต่อจากตรงนี้ได้เลย', 5.0)

func save_progress() -> void:
	GameManager.save_progress({'checkpoint': active_checkpoint, 'elapsed': elapsed, 'falls': falls, 'foods': foods_eaten})

# ---------- atmosphere ---------- #

func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var result := {}
	for key in a:
		result[key] = lerp(a[key], b[key], t)
	return result

func zone_at(height: float) -> int:
	var zone := 0
	for i in zone_heights.size():
		if height >= zone_heights[i] - 1.0:
			zone = i
	return zone

func apply_look(height: float) -> void:
	var look: Dictionary = ZONE_LOOKS[0]
	for i in range(1, mini(zone_heights.size(), ZONE_LOOKS.size())):
		var t := smoothstep(zone_heights[i] - 8.0, zone_heights[i] + 2.0, height)
		look = blend(look, ZONE_LOOKS[i], t)
	sky_material.sky_top_color = look['sky_top']
	sky_material.sky_horizon_color = look['horizon']
	sky_material.ground_horizon_color = look['ground_horizon']
	sky_material.ground_bottom_color = look['ground_bottom']
	environment.fog_light_color = look['fog']
	environment.fog_density = look['fog_density']
	environment.fog_enabled = look['fog_density'] > 0.0001
	environment.ambient_light_color = look['ambient']
	environment.ambient_light_energy = look['ambient_energy']
	sun.light_color = look['sun']
	sun.light_energy = look['sun_energy']
	if star_material:
		star_material.albedo_color.a = look['stars']
		star_field.visible = look['stars'] > 0.01
	# Space props only appear once Aof is above the clouds; the flat Earth
	# disappears in space so the horizon reads as open sky.
	var space_height: float = zone_heights[zone_heights.size() - 1]
	if space_scenery:
		space_scenery.visible = height > space_height - 12.0
	for node in earth_visuals:
		node.visible = height < space_height - 4.0

func focus_height() -> float:
	if player:
		return player.global_position.y
	var camera := get_viewport().get_camera_3d()
	return camera.global_position.y if camera else 0.0

func _process(delta: float) -> void:
	apply_look(focus_height())
	if cinematic or hud == null:
		return
	dialog_time = maxf(0.0, dialog_time - delta)
	dialog.visible = dialog_time > 0.0
	toast_time = maxf(0.0, toast_time - delta)
	toast.modulate.a = clampf(toast_time, 0.0, 1.0)
	zone_title_time = maxf(0.0, zone_title_time - delta)
	zone_title.modulate.a = clampf(zone_title_time, 0.0, 1.0)
	update_hud()

# ---------- gameplay ---------- #

func _physics_process(delta: float) -> void:
	if cinematic:
		return
	if not finished:
		elapsed += delta
	best_height = maxf(best_height, player.global_position.y)
	if player.noclip:
		return
	if player.global_position.y < respawn_position.y - 14.0:
		respawn()
		return
	if Input.is_action_just_pressed('return_checkpoint') and not finished:
		respawn(false)
		return
	var zone := zone_at(player.global_position.y)
	if zone > shown_zone:
		shown_zone = zone
		show_zone_title(zone)

func _unhandled_input(event: InputEvent) -> void:
	if cinematic or finished:
		return
	if event.is_action_pressed('mouse_visible'):
		get_viewport().set_input_as_handled()
		set_paused(not get_tree().paused)
	elif event.is_action_pressed('admin_noclip'):
		get_viewport().set_input_as_handled()
		player.set_noclip(not player.noclip)
		show_toast('ADMIN: บินทะลุ (No Clip) เปิด' if player.noclip else 'ADMIN: บินทะลุ ปิด')
	elif player.noclip and event is InputEventKey and event.pressed and not event.echo:
		admin_teleport(event.physical_keycode)

## Admin teleports while flying: 1-3 = Uncle Oli of each zone, 4 = summit.
func admin_teleport(key: Key) -> void:
	var target := Vector3.INF
	if key >= KEY_1 and key <= KEY_3 and key - KEY_1 < checkpoints.get_child_count():
		target = checkpoints.get_child(key - KEY_1).get_node('Spawn').global_position + Vector3(0, 1.5, 3)
	elif key == KEY_4:
		target = get_node('Platforms/Summit').global_position + Vector3(0, 3, 8)
	if target != Vector3.INF:
		player.global_position = target
		player.spring_arm.snap_to_player()
		get_viewport().set_input_as_handled()

func activate_checkpoint(checkpoint: Area3D) -> void:
	if finished or checkpoint.checkpoint_index <= active_checkpoint:
		return
	checkpoints.get_child(active_checkpoint).set_active(false)
	active_checkpoint = checkpoint.checkpoint_index
	respawn_position = checkpoint.get_node('Spawn').global_position
	checkpoint.set_active(true)
	save_progress()
	show_toast('บันทึกจุดเซฟแล้ว! (โซน %d)' % (active_checkpoint + 1))
	say('ลุงโอลี่', checkpoint.message, 10.0)

func respawn(count_fall: bool = true) -> void:
	if count_fall:
		falls += 1
		show_toast('ตกลงมาแล้ว! กลับไปหาลุงโอลี่')
	player.reset_to_spawn(respawn_position)

func on_food_eaten(food: Node) -> void:
	foods_eaten += 1
	show_toast('ยัม! กระโดดสูงขึ้นชั่วคราว (%s)' % food.food_name)

func finish_game() -> void:
	if finished:
		return
	finished = true
	GameManager.clear_progress()
	if player.noclip:
		player.set_noclip(false)
	player.controls_locked = true
	player.apply_jump_boost(6.0)
	say('ผู้พิทักษ์ดวงดาว', KEEPER_LINES, 30.0)
	await get_tree().create_timer(4.0).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show_ending()

# ---------- HUD ---------- #

func build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = 'HUD'
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	# Minimal HUD: only the food boost (while active), messages and admin state.
	boost_row = HBoxContainer.new()
	boost_row.add_theme_constant_override('separation', 8)
	boost_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 20)
	boost_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(boost_row)
	boost_row.add_child(UiKit.label('พลังอาหาร', 16, Color(1, 0.85, 0.4), 4))
	boost_bar = ProgressBar.new()
	boost_bar.custom_minimum_size = Vector2(150, 14)
	boost_bar.show_percentage = false
	boost_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boost_bar.add_theme_stylebox_override('background', UiKit.box(Color(0, 0, 0, 0.4), 7))
	boost_bar.add_theme_stylebox_override('fill', UiKit.box(Color(1, 0.78, 0.25), 7))
	boost_row.add_child(boost_bar)
	admin_label = UiKit.label('ADMIN · NO CLIP
WASD บิน · Space ขึ้น · Ctrl ลง · Shift เร็ว
1-3 ไปจุดเซฟโซน 1-3 · 4 ไปยอดสุด · Insert ปิด', 15, Color(1, 0.55, 0.45), 4)
	admin_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	admin_label.visible = false
	hud.add_child(admin_label)
	dialog = UiKit.dialogue_card()
	dialog.custom_minimum_size = Vector2(760, 0)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(dialog)
	var dialog_box: VBoxContainer = dialog.get_meta('content')
	dialog_box.add_theme_constant_override('separation', 4)
	dialog_name = UiKit.label('', 20, UiKit.ORANGE_LIGHT)
	dialog_box.add_child(dialog_name)
	dialog_text = UiKit.label('', 18)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size.x = 700
	dialog_box.add_child(dialog_text)
	dialog.visible = false
	toast = UiKit.label('', 26, UiKit.MINT, 8)
	toast.name = 'Toast'
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 56)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(toast)
	zone_title = UiKit.label('', 46, Color.WHITE, 12)
	zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 104)
	zone_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(zone_title)

func update_hud() -> void:
	boost_row.visible = player.boost_time > 0.0
	if boost_row.visible:
		boost_bar.value = player.boost_time / player.boost_duration * 100.0
	admin_label.visible = player.noclip

func format_time(seconds: float) -> String:
	return '%02d:%02d' % [int(seconds) / 60, int(seconds) % 60]

func say(speaker: String, text: String, duration: float) -> void:
	if hud == null:
		return
	dialog_name.text = speaker
	dialog_text.text = text
	dialog_text.visible_ratio = 0.0
	create_tween().tween_property(dialog_text, 'visible_ratio', 1.0, minf(2.5, text.length() * 0.02))
	dialog_time = duration

func show_toast(text: String) -> void:
	toast.text = text
	toast_time = 3.0

func show_zone_title(zone: int) -> void:
	zone_title.text = 'โซน %d\n%s' % [zone + 1, zone_names[zone]]
	zone_title_time = 3.5

# ---------- pause & ending ---------- #

const PAUSE_ART := 'res://Assets/Paused Button/'

## Image button from Assets/Paused Button/ui: <name>.png normally, <name>_hover.png
## while selected. Hovering with the mouse selects it, so exactly one button is
## highlighted at a time (mouse and keyboard agree).
func pause_button(normal: String, hold: String, size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	var normal_texture: Texture2D = load(PAUSE_ART + normal)
	var hold_texture: Texture2D = load(PAUSE_ART + hold)
	button.texture_normal = normal_texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pivot_offset = size * 0.5
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_entered.connect(func(): button.grab_focus())
	button.focus_entered.connect(func():
		button.texture_normal = hold_texture
		button.create_tween().tween_property(button, 'scale', Vector2.ONE * 1.04, 0.08))
	button.focus_exited.connect(func():
		button.texture_normal = normal_texture
		button.create_tween().tween_property(button, 'scale', Vector2.ONE, 0.08))
	return button

func set_paused(value: bool) -> void:
	get_tree().paused = value
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_overlay = Control.new()
		pause_overlay.name = 'Pause'
		pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		hud.add_child(pause_overlay)
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.03, 0.08, 0.6)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		pause_overlay.add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		pause_overlay.add_child(center)
		# PAUSED panel artwork with the four image buttons laid over it.
		var panel := TextureRect.new()
		panel.name = 'Panel'
		panel.texture = load(PAUSE_ART + 'PausedPanel.png')
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		panel.custom_minimum_size = Vector2(480, 420)
		center.add_child(panel)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override('separation', 9)
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.offset_top = 96
		column.offset_bottom = -26
		panel.add_child(column)
		# All button images are normalized to 672x148 (see Assets/Paused Button/ui).
		var size := Vector2(300, 66)
		var resume := pause_button('ui/Resume.png', 'ui/Resume_hover.png', size)
		resume.name = 'Resume'
		resume.pressed.connect(func(): set_paused(false))
		column.add_child(resume)
		var back := pause_button('ui/Restart.png', 'ui/Restart_hover.png', size)
		back.name = 'RestartCheckpoint'
		back.pressed.connect(func():
			set_paused(false)
			respawn(false))
		column.add_child(back)
		var settings := pause_button('ui/Setting.png', 'ui/Setting_hover.png', size)
		settings.name = 'Setting'
		settings.pressed.connect(func(): open_popup(UiKit.options_overlay(close_popup)))
		column.add_child(settings)
		var menu := pause_button('ui/Menu.png', 'ui/Menu_hover.png', size)
		menu.name = 'MainMenu'
		menu.pressed.connect(go_to_menu)
		column.add_child(menu)
		panel.pivot_offset = panel.custom_minimum_size * 0.5
		panel.scale = Vector2.ONE * 0.85
		panel.create_tween().tween_property(panel, 'scale', Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		resume.grab_focus()
	else:
		close_popup()
		if pause_overlay:
			pause_overlay.queue_free()
			pause_overlay = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_popup(node: Control) -> void:
	close_popup()
	popup = node
	hud.add_child(popup)
	popup.get_meta('close').grab_focus()

func close_popup() -> void:
	if popup:
		popup.queue_free()
		popup = null

func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)

const CLEAR_ART := 'res://Assets/GAMECLEARASSETS/ui/'

## Image button for the Game Clear screen: grows and brightens while selected.
func clear_button(file: String, size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = load(CLEAR_ART + file)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = size
	button.pivot_offset = size * 0.5
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_entered.connect(func(): button.grab_focus())
	button.focus_entered.connect(func():
		button.self_modulate = Color(1.18, 1.18, 1.18)
		button.create_tween().tween_property(button, 'scale', Vector2.ONE * 1.08, 0.1))
	button.focus_exited.connect(func():
		button.self_modulate = Color.WHITE
		button.create_tween().tween_property(button, 'scale', Vector2.ONE, 0.1))
	return button

## One stat line: icon, name, value on a rounded dark bar.
func clear_row(icon: String, title: String, value: String) -> PanelContainer:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.2, 0.75)
	style.set_corner_radius_all(26)
	style.border_color = Color(0.25, 0.4, 0.75, 0.6)
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 26
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override('panel', style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 16)
	bar.add_child(row)
	var picture := TextureRect.new()
	picture.texture = load(CLEAR_ART + icon)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(42, 42)
	row.add_child(picture)
	var name_label := UiKit.label(title, 21, Color(0.92, 0.95, 1.0), 4)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	var value_label := UiKit.label(value, 28, Color(1.0, 0.8, 0.22), 5)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	return bar

## Game Clear screen built from Assets/GAMECLEARASSETS (layout of EXAMPLE CLAER.png).
func show_ending() -> void:
	dialog_time = 0.0
	zone_title_time = 0.0
	# Freeze the HUD: only the Game Clear screen is shown.
	set_process(false)
	boost_row.hide()
	dialog.visible = false
	toast.modulate.a = 0.0
	zone_title.modulate.a = 0.0
	admin_label.hide()
	var overlay := Control.new()
	overlay.name = 'Ending'
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	# Stat panel: the frame stretched 9-slice so its corners stay crisp.
	var panel := NinePatchRect.new()
	panel.name = 'Panel'
	panel.texture = load(CLEAR_ART + 'frame.png')
	panel.patch_margin_left = 48
	panel.patch_margin_right = 48
	panel.patch_margin_top = 48
	panel.patch_margin_bottom = 48
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -360
	panel.offset_right = 360
	panel.offset_top = -190
	panel.offset_bottom = 268
	overlay.add_child(panel)
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 48
	content.offset_right = -48
	content.offset_top = 92
	content.offset_bottom = -96
	content.add_theme_constant_override('separation', 10)
	panel.add_child(content)
	var heading := HBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override('separation', 14)
	content.add_child(heading)
	for side in 2:
		var star := TextureRect.new()
		star.texture = load(CLEAR_ART + 'star.png')
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(34, 34)
		heading.add_child(star)
		if side == 0:
			heading.add_child(UiKit.label('LEVEL COMPLETE!', 32, Color.WHITE, 6))
	content.add_child(clear_row('clock.png', 'เวลาที่ใช้', format_time(elapsed)))
	content.add_child(clear_row('star.png', 'อาหารที่เก็บได้', str(foods_eaten)))
	content.add_child(clear_row('coin.png', 'จำนวนครั้งที่ตก', str(falls)))
	content.add_child(clear_row('diamond.png', 'ความสูงสูงสุด', '%.1f M' % best_height))
	# GAME CLEAR title overlapping the top of the panel.
	var title := TextureRect.new()
	title.name = 'Title'
	title.texture = load(CLEAR_ART + 'title.png')
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -210
	title.offset_right = 210
	title.offset_top = -352
	title.offset_bottom = -120
	title.pivot_offset = Vector2(210, 116)
	overlay.add_child(title)
	# NEXT (credits) / RETRY (new climb) / MENU along the bottom edge.
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override('separation', 14)
	buttons.set_anchors_preset(Control.PRESET_CENTER)
	buttons.offset_left = -380
	buttons.offset_right = 380
	buttons.offset_top = 214
	buttons.offset_bottom = 298
	overlay.add_child(buttons)
	var credits := clear_button('next.png', Vector2(222, 84))
	credits.name = 'ShowCredits'
	credits.pressed.connect(func(): open_popup(UiKit.credits_overlay(close_popup)))
	buttons.add_child(credits)
	var again := clear_button('retry.png', Vector2(212, 84))
	again.name = 'Retry'
	again.pressed.connect(func():
		GameManager.clear_progress()
		get_tree().reload_current_scene())
	buttons.add_child(again)
	var menu := clear_button('menu.png', Vector2(206, 84))
	menu.name = 'Menu'
	menu.pressed.connect(go_to_menu)
	buttons.add_child(menu)
	# Pop in: title bounces, panel slides up.
	title.scale = Vector2.ONE * 0.3
	title.create_tween().tween_property(title, 'scale', Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel.modulate.a = 0.0
	panel.position.y += 40
	var slide := panel.create_tween().set_parallel()
	slide.tween_property(panel, 'modulate:a', 1.0, 0.35)
	slide.tween_property(panel, 'position:y', panel.position.y - 40, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	credits.grab_focus()
