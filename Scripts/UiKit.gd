class_name UiKit
extends RefCounted
## Shared look for menus, story, HUD and credits.

const ORANGE := Color(1.0, 0.52, 0.18)
const ORANGE_LIGHT := Color(1.0, 0.72, 0.36)
const INK := Color(0.07, 0.09, 0.16, 0.86)
const INK_SOFT := Color(0.10, 0.13, 0.22, 0.72)
const CREAM := Color(1.0, 0.96, 0.88)
const MINT := Color(0.45, 1.0, 0.72)

const TEAM := [
	['663380034-6', 'ณัฐดนัย สมสวย', 'Ai'],
	['663380534-6', 'วรพันธุ์ คำทะเนตร', 'Ai'],
	['663380285-1', 'ภควัต ชมดง', 'Ai'],
	['663380532-0', 'ภูวรินทร์ ไชยพิมูล', 'Ai'],
]
const ASSET_CREDITS := [
	'3D Platformer Starter Kit - Silver Demon Studios (MIT)',
	'KayKit City Builder Bits - Kay Lousberg (CC0)',
	'Food Kit - Kenney (CC0)',
	'Planet - Quaternius / Asteroid - J-Toastie / Spaceship - Liz Reddington',
	'Flying Saucer, Moon, International Space Station - Poly by Google (CC-BY)',
	'ฟอนต์ Noto Sans Thai (SIL OFL)',
]

static func box(color: Color, radius: int = 14, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	return style

static func label(text: String, size: int = 20, color: Color = CREAM, outline: int = 0) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override('font_size', size)
	result.add_theme_color_override('font_color', color)
	if outline > 0:
		result.add_theme_constant_override('outline_size', outline)
		result.add_theme_color_override('font_outline_color', Color(0.05, 0.05, 0.12))
	return result

static func button(text: String, primary: bool = true, width: float = 300.0) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(width, 54)
	result.add_theme_font_size_override('font_size', 22)
	var base := ORANGE if primary else Color(0.16, 0.2, 0.32, 0.9)
	var hover := ORANGE_LIGHT if primary else Color(0.26, 0.32, 0.48, 0.95)
	result.add_theme_stylebox_override('normal', box(base, 16))
	result.add_theme_stylebox_override('hover', box(hover, 16))
	result.add_theme_stylebox_override('pressed', box(base.darkened(0.2), 16))
	result.add_theme_stylebox_override('focus', box(Color.TRANSPARENT, 16, CREAM, 3))
	result.add_theme_stylebox_override('disabled', box(base.darkened(0.4), 16))
	result.add_theme_color_override('font_color', Color(0.12, 0.07, 0.03) if primary else CREAM)
	result.add_theme_color_override('font_hover_color', Color(0.12, 0.07, 0.03) if primary else Color.WHITE)
	result.add_theme_color_override('font_focus_color', Color(0.12, 0.07, 0.03) if primary else Color.WHITE)
	result.add_theme_color_override('font_pressed_color', Color(0.12, 0.07, 0.03) if primary else Color.WHITE)
	return result

## Card with padding; add content to card.get_meta('content').
static func card(color: Color = INK, radius: int = 20) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := box(color, radius, Color(1, 1, 1, 0.12), 2)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 18
	panel.add_theme_stylebox_override('panel', style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override('separation', 10)
	panel.add_child(content)
	panel.set_meta('content', content)
	return panel

## Dialogue box (Uncle Oli, Star Keeper) in the crown/star frame from
## Assets/GAMECLEARASSETS/story.png, drawn 9-slice so the corners keep their shape.
## Add content to dialogue_card().get_meta('content').
static func dialogue_card() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = load('res://Assets/GAMECLEARASSETS/ui/story_frame_small.png')
	style.texture_margin_left = 63
	style.texture_margin_right = 58
	style.texture_margin_top = 53
	style.texture_margin_bottom = 55
	style.content_margin_left = 38
	style.content_margin_right = 42
	style.content_margin_top = 54
	style.content_margin_bottom = 32
	panel.add_theme_stylebox_override('panel', style)
	var content := VBoxContainer.new()
	content.add_theme_constant_override('separation', 10)
	panel.add_child(content)
	panel.set_meta('content', content)
	return panel

## Full-screen dimmed overlay with a centered card. Returns the overlay.
static func overlay(card_width: float = 640.0) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := card()
	panel.custom_minimum_size.x = card_width
	center.add_child(panel)
	root.set_meta('content', panel.get_meta('content'))
	return root

static func credits_overlay(on_close: Callable, close_text: String = 'ปิด') -> Control:
	var root := overlay(700)
	root.name = 'Credits'
	var content: VBoxContainer = root.get_meta('content')
	var title := label('เครดิต', 38, ORANGE_LIGHT, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var game := label('Just go up!!  ·  กลุ่ม 4\nCP352203 / CP410844 Computer Game Development  ·  ปีการศึกษา 2569', 16, Color(0.8, 0.85, 0.95))
	game.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(game)
	content.add_child(HSeparator.new())
	var heading := label('ผู้จัดทำ', 22, MINT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override('h_separation', 28)
	grid.add_theme_constant_override('v_separation', 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for member in TEAM:
		grid.add_child(label(member[0], 20, ORANGE_LIGHT))
		grid.add_child(label(member[1], 20, CREAM))
		grid.add_child(label('สาขา ' + member[2], 20, Color(0.75, 0.82, 0.95)))
	content.add_child(grid)
	content.add_child(HSeparator.new())
	var assets_heading := label('Asset ที่ใช้', 18, MINT)
	assets_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(assets_heading)
	var assets := label('\n'.join(ASSET_CREDITS), 14, Color(0.78, 0.82, 0.9))
	assets.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(assets)
	var close := button(close_text, true, 220)
	close.name = 'Close'
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(on_close)
	content.add_child(close)
	root.set_meta('close', close)
	return root

static func controls_overlay(on_close: Callable) -> Control:
	var root := overlay(600)
	root.name = 'Controls'
	var content: VBoxContainer = root.get_meta('content')
	var title := label('วิธีเล่น', 36, ORANGE_LIGHT, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override('h_separation', 26)
	grid.add_theme_constant_override('v_separation', 8)
	for row in [['W A S D', 'เดิน'], ['Shift', 'วิ่ง'], ['Space', 'กระโดด (ต่อกลางอากาศได้ 3 ครั้ง ครั้งที่ 3 ตีลังกา!)'],
			['เมาส์', 'หมุนกล้อง'], ['R', 'กลับไปจุดเซฟของลุงโอลี่'], ['Esc', 'หยุดเกม / ปล่อยเมาส์']]:
		grid.add_child(label(row[0], 20, ORANGE_LIGHT))
		var text := label(row[1], 19)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 380
		grid.add_child(text)
	content.add_child(grid)
	var tips := label('• เก็บอาหารที่ลอยอยู่เพื่อกระโดดสูงขึ้นชั่วคราว\n• ของบางชิ้นเลื่อน หมุน หรือลอยไปมา รอจังหวะให้ดี\n• ยืนข้างลุงโอลี่เพื่อบันทึกจุดเซฟของแต่ละโซน', 17, Color(0.8, 0.88, 1.0))
	content.add_child(tips)
	var close := button('เข้าใจแล้ว', true, 220)
	close.name = 'Close'
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(on_close)
	content.add_child(close)
	root.set_meta('close', close)
	return root

static func slider_row(text: String, value: float, low: float, high: float, step: float, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 16)
	var name_label := label(text, 20, ORANGE_LIGHT)
	name_label.custom_minimum_size.x = 170
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var amount := label('%d%%' % roundi(value / high * 100.0), 18)
	amount.custom_minimum_size.x = 60
	slider.value_changed.connect(func(v: float):
		amount.text = '%d%%' % roundi(v / high * 100.0)
		on_change.call(v))
	row.add_child(slider)
	row.add_child(amount)
	return row

## Settings (saved by GameManager) plus the controls list.
static func options_overlay(on_close: Callable) -> Control:
	# Looked up at runtime so UiKit compiles even where autoload names are unknown.
	var settings: Node = (Engine.get_main_loop() as SceneTree).root.get_node('GameManager')
	var root := overlay(640)
	root.name = 'Options'
	var content: VBoxContainer = root.get_meta('content')
	var title := label('ตั้งค่า', 36, ORANGE_LIGHT, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(slider_row('ระดับเสียง', settings.volume, 0.0, 1.0, 0.05, func(v: float):
		settings.volume = v
		settings.apply_settings()))
	content.add_child(slider_row('ความไวเมาส์', settings.mouse_sensitivity, 0.04, 0.4, 0.01, func(v: float):
		settings.mouse_sensitivity = v
		for camera in Engine.get_main_loop().get_nodes_in_group('PlayerCamera'):
			camera.mouse_sensitivity = v))
	if not OS.has_feature('web'):
		var fullscreen := CheckButton.new()
		fullscreen.text = 'เต็มจอ'
		fullscreen.add_theme_font_size_override('font_size', 20)
		fullscreen.button_pressed = settings.fullscreen
		fullscreen.toggled.connect(func(on: bool):
			settings.fullscreen = on
			settings.apply_settings())
		content.add_child(fullscreen)
	content.add_child(HSeparator.new())
	var heading := label('วิธีเล่น', 22, MINT)
	content.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override('h_separation', 26)
	grid.add_theme_constant_override('v_separation', 4)
	for row in [['W A S D', 'เดิน'], ['Shift', 'วิ่ง'], ['Space', 'กระโดด ต่อกลางอากาศได้ 3 ครั้ง (ครั้งที่ 3 ตีลังกา)'],
			['เมาส์', 'หมุนกล้อง'], ['R', 'กลับไปจุดเซฟของลุงโอลี่'], ['Esc', 'หยุดเกม']]:
		grid.add_child(label(row[0], 18, ORANGE_LIGHT))
		grid.add_child(label(row[1], 18))
	content.add_child(grid)
	var close := button('บันทึกและปิด', true, 240)
	close.name = 'Close'
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func():
		settings.save_settings()
		on_close.call())
	content.add_child(close)
	root.set_meta('close', close)
	return root
