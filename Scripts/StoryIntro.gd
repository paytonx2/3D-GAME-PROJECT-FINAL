extends Node3D
## Story cutscene before the climb (from the game design document).
## Space / Enter / click: next page   Esc: skip

const WORLD_SCENE := 'res://Scenes/world.tscn'
const AOF_SCENE := 'res://Assets/model/Aof/AofPlayer.tscn'
const PAGES := [
	{'title': 'หลังพายุใหญ่', 'text': 'วันหนึ่ง หลังพายุใหญ่พัดผ่านเมือง\nได้ปรากฏ "เส้นทางลอยฟ้า" ประหลาดขึ้นกลางเมือง', 'shot': 'plaza_up'},
	{'title': 'เส้นทางลอยฟ้า', 'text': 'บ้าน ท่อน้ำ รถยนต์ ก้อนหิน และเศษซากมากมาย\nลอยเรียงต่อกันขึ้นไปจนทะลุเมฆ', 'shot': 'rise'},
	{'title': 'ตำนานเก่า', 'text': 'ตำนานเก่าเล่าว่า ใครที่ไปถึงจุดสูงสุดได้\nจะได้พบกับ "ดาวแห่งความปรารถนา" ที่ทำให้คำขอหนึ่งข้อเป็นจริง', 'shot': 'star'},
	{'title': 'Aof (ออฟ)', 'text': 'Aof เด็กหนุ่มธรรมดาที่ไม่มีพลังพิเศษใด ๆ\nตัดสินใจออกเดินทางเพียงลำพัง โดยมีลุงโอลี่นกฮูกชราคอยช่วยตามจุดพัก', 'shot': 'aof'},
	{'title': 'สามโซน', 'text': 'เขาต้องผ่านเมืองที่ถูกยกลอยขึ้นฟ้า ทะเลเมฆ\nและห้วงอวกาศที่ทุกสิ่งลอยไปมา', 'shot': 'zones'},
	{'title': 'กฎเพียงข้อเดียว', 'text': '"อย่ามองลงข้างล่าง\nแค่ขึ้นไปเรื่อย ๆ"', 'shot': 'go'},
]
const PAGE_TIME := 7.0
var world: Node3D
var camera: Camera3D
var aof: Node3D
var page: int = -1
var page_time: float = 0.0
var shots := {}
var title_label: Label
var text_label: Label
var progress: Label
var leaving: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	world = load(WORLD_SCENE).instantiate()
	world.cinematic = true
	world.name = 'Backdrop'
	add_child(world)
	var checkpoints := world.get_node('Checkpoints')
	var spawn: Vector3 = checkpoints.get_child(0).get_node('Spawn').global_position
	var cloud: Vector3 = checkpoints.get_child(1).global_position
	var space: Vector3 = checkpoints.get_child(2).global_position
	var summit: Vector3 = world.get_node('Platforms/Summit').global_position
	var first: Vector3 = world.get_node('Platforms/Platform03').global_position
	aof = load(AOF_SCENE).instantiate()
	aof.name = 'Aof'
	world.add_child(aof)
	aof.global_position = spawn
	aof.rotation_degrees.y = 180.0
	# Each shot moves the camera from one [position, look target] to another.
	shots = {
		'plaza_up': [[spawn + Vector3(2, 1.8, 6), first + Vector3(0, 2, 0)], [spawn + Vector3(-2, 1.2, 6), first + Vector3(0, 9, -4)]],
		'rise': [[first + Vector3(12, 2, 10), first + Vector3(0, 6, 0)], [cloud + Vector3(14, -4, 14), cloud + Vector3(0, 2, 0)]],
		'star': [[summit + Vector3(7, 3, 9), summit + Vector3(0, 2, -1.5)], [summit + Vector3(3, 2.6, 4.5), summit + Vector3(0, 2.2, -1.5)]],
		'aof': [[spawn + Vector3(0.8, 1.5, -4.2), spawn + Vector3(1.0, 1.1, -0.5)], [spawn + Vector3(-0.6, 1.4, -3.6), spawn + Vector3(1.0, 1.2, -0.5)]],
		'zones': [[cloud + Vector3(9, 3, 9), cloud + Vector3(0, 6, 0)], [space + Vector3(10, 2, 10), space + Vector3(0, 8, 0)]],
		'go': [[spawn + Vector3(0.4, 1.6, 3.2), spawn + Vector3(0, 3, -10)], [spawn + Vector3(0.3, 1.0, 2.2), first + Vector3(0, 14, -6)]],
	}
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.far = 2000.0
	add_child(camera)
	camera.current = true
	build_ui()
	next_page()

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = 'StoryCanvas'
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.92)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.custom_minimum_size.y = 64
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
	# Story text sits in the crown/star frame (Assets/GAMECLEARASSETS/story.png),
	# drawn 9-slice so the corner ornaments keep their shape.
	var frame := NinePatchRect.new()
	frame.name = 'StoryFrame'
	frame.texture = load('res://Assets/GAMECLEARASSETS/ui/story_frame.png')
	frame.patch_margin_left = 125
	frame.patch_margin_right = 115
	frame.patch_margin_top = 105
	frame.patch_margin_bottom = 110
	frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	frame.offset_left = -480
	frame.offset_right = 480
	frame.offset_top = -330
	frame.offset_bottom = -26
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 70
	content.offset_right = -70
	content.offset_top = 100
	content.offset_bottom = -50
	content.add_theme_constant_override('separation', 6)
	frame.add_child(content)
	title_label = UiKit.label('', 30, UiKit.ORANGE_LIGHT, 5)
	content.add_child(title_label)
	text_label = UiKit.label('', 24, UiKit.CREAM, 3)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(800, 74)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(text_label)
	progress = UiKit.label('', 15, Color(0.75, 0.8, 0.95))
	# Left-aligned so it stays clear of the star in the bottom-right corner.
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(progress)
	var skip := UiKit.button('ข้าม ▶▶', false, 140)
	skip.name = 'Skip'
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	skip.custom_minimum_size.y = 42
	skip.pressed.connect(begin_climb)
	root.add_child(skip)

func next_page() -> void:
	if text_label.visible_ratio < 1.0 and page >= 0:
		# First press finishes the typewriter; the next one turns the page.
		text_label.visible_ratio = 1.0
		return
	page += 1
	if page >= PAGES.size():
		begin_climb()
		return
	page_time = 0.0
	title_label.text = PAGES[page]['title']
	text_label.text = PAGES[page]['text']
	text_label.visible_ratio = 0.0
	progress.text = '%d / %d   ·   Space / คลิก: ต่อไป   ·   Esc: ข้าม' % [page + 1, PAGES.size()]

func _process(delta: float) -> void:
	if page < 0 or page >= PAGES.size():
		return
	page_time += delta
	text_label.visible_ratio = minf(1.0, text_label.visible_ratio + delta * 35.0 / maxf(1.0, text_label.text.length()))
	var shot: Array = shots[PAGES[page]['shot']]
	var t := smoothstep(0.0, PAGE_TIME, page_time)
	var position: Vector3 = shot[0][0].lerp(shot[1][0], t)
	var target: Vector3 = shot[0][1].lerp(shot[1][1], t)
	camera.position = position
	camera.look_at(target)
	if page_time > PAGE_TIME + 2.5:
		text_label.visible_ratio = 1.0
		next_page()

func _unhandled_input(event: InputEvent) -> void:
	var skip: bool = event.is_action_pressed('mouse_visible')
	var advance: bool = event.is_action_pressed('jump') or event.is_action_pressed('ui_accept') or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if leaving or not (skip or advance):
		return
	# Mark handled before acting: the last page leaves this scene.
	get_viewport().set_input_as_handled()
	if skip:
		begin_climb()
	else:
		next_page()

func begin_climb() -> void:
	if leaving:
		return
	leaving = true
	# Deferred so the current input/process callback finishes inside the tree.
	get_tree().change_scene_to_file.call_deferred(WORLD_SCENE)
