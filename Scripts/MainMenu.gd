extends Control
## Title screen. The poster, buttons and footer are nodes in main_menu.tscn
## (move or resize them in the editor); this script wires them up and animates them.

const WORLD_SCENE := 'res://Scenes/world.tscn'
const STORY_SCENE := 'res://Scenes/story.tscn'
const ART := 'res://Assets/BUTTON/'
# name, normal, hover, rect (position, size) in the 1280x720 layout.
const DEFAULT_BUTTONS := [
	['Play', 'StartButton.png', 'StartButtonHOVER.png', Rect2(124, 283.5, 350, 117)],
	['Continue', 'GameButton.png', 'Continue ButtonHOVE.png', Rect2(149, 371, 292, 100)],
	['Options', 'OptionButton .png', 'Option ButtonHOVE.png', Rect2(149, 436, 292, 100)],
	['Credits', 'CreditButton.png', 'CreditButtonHOVE.png', Rect2(160, 507, 270, 90)],
	['Quit', 'ExitButton.png', 'ExitButtonHOVE.png', Rect2(160, 572, 270, 90)],
]
var background: TextureRect
var play_button: TextureButton
var continue_button: TextureButton
var options_button: TextureButton
var credits_button: TextureButton
var quit_button: TextureButton
var ui: Control
var popup: Control
var starting: bool = false
var time: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	ui = self
	ensure_nodes()
	background = $Background
	play_button = $Buttons/Play
	continue_button = $Buttons/Continue
	options_button = $Buttons/Options
	credits_button = $Buttons/Credits
	quit_button = $Buttons/Quit
	var buttons := [play_button, continue_button, options_button, credits_button, quit_button]
	for i in buttons.size():
		var button: TextureButton = buttons[i]
		button.focus_mode = Control.FOCUS_ALL
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(func(): if not button.disabled: button.grab_focus())
		button.focus_entered.connect(func(): bump(button, 1.05))
		button.focus_exited.connect(func(): bump(button, 1.0))
		# Slide in from the left, one after another, to where the editor placed it.
		var target_x := button.position.x
		button.position.x -= 420
		button.modulate.a = 0.0
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.08 * i)
		tween.tween_property(button, 'position:x', target_x, 0.45)
		tween.parallel().tween_property(button, 'modulate:a', 1.0, 0.3)
	play_button.pressed.connect(start_game)
	continue_button.pressed.connect(continue_game)
	options_button.pressed.connect(func(): open_popup(UiKit.options_overlay(close_popup)))
	credits_button.pressed.connect(func(): open_popup(UiKit.credits_overlay(close_popup)))
	quit_button.pressed.connect(func(): get_tree().quit())
	continue_button.disabled = not GameManager.has_progress()
	if continue_button.disabled:
		continue_button.self_modulate = Color(0.55, 0.55, 0.6, 1.0)
		continue_button.focus_mode = Control.FOCUS_NONE
		continue_button.tooltip_text = 'ยังไม่มีจุดเซฟ'
	quit_button.visible = not OS.has_feature('web')
	play_button.grab_focus()

## Creates any missing poster/button/footer node, so the menu still works if
## main_menu.tscn was saved without them.
func ensure_nodes() -> void:
	if not has_node('Background'):
		var poster := TextureRect.new()
		poster.name = 'Background'
		poster.texture = load(ART + 'Just_GO_UP.png')
		poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		poster.set_anchors_preset(Control.PRESET_FULL_RECT)
		poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(poster)
		move_child(poster, 0)
	if not has_node('Buttons'):
		var holder := Control.new()
		holder.name = 'Buttons'
		holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)
	var buttons: Control = $Buttons
	for spec in DEFAULT_BUTTONS:
		if buttons.has_node(NodePath(spec[0])):
			continue
		var button := TextureButton.new()
		button.name = spec[0]
		button.texture_normal = load(ART + spec[1])
		button.texture_hover = load(ART + spec[2])
		button.texture_pressed = button.texture_hover
		button.texture_focused = button.texture_hover
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.position = spec[3].position
		button.size = spec[3].size
		buttons.add_child(button)
	if not has_node('Footer'):
		var footer := UiKit.label('กลุ่ม 4 · CP352203 / CP410844 Computer Game Development · ปีการศึกษา 2569', 14, Color(1, 1, 1, 0.9), 5)
		footer.name = 'Footer'
		footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
		footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
		add_child(footer)

func bump(button: TextureButton, value: float) -> void:
	create_tween().tween_property(button, 'scale', Vector2.ONE * value, 0.12)

func _process(delta: float) -> void:
	time += delta
	# Gentle drift of the poster so the title screen feels alive.
	background.pivot_offset = background.size * 0.5
	background.scale = Vector2.ONE * (1.03 + sin(time * 0.25) * 0.02)

func open_popup(node: Control) -> void:
	close_popup()
	popup = node
	add_child(popup)
	popup.get_meta('close').grab_focus()

func close_popup() -> void:
	if popup:
		popup.queue_free()
		popup = null
		play_button.grab_focus()

func start_game() -> void:
	if starting:
		return
	starting = true
	GameManager.clear_progress()
	GameManager.continuing = false
	get_tree().change_scene_to_file.call_deferred(STORY_SCENE)

func continue_game() -> void:
	if starting or not GameManager.has_progress():
		return
	starting = true
	GameManager.continuing = true
	get_tree().change_scene_to_file.call_deferred(WORLD_SCENE)
