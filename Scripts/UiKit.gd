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

## ---------- Framed panels (Credits, Settings) ---------- ##

const FRAME_TALL := 'res://Assets/image/ui/frame_tall.png'
const STAR_ICON := 'res://Assets/GAMECLEARASSETS/ui/star.png'
const STAR_SMALL := 'res://Assets/image/ui/star_small.png'
const GOLD := Color(1.0, 0.82, 0.25)
const SKY := Color(0.62, 0.82, 1.0)

## Dimmed full-screen overlay holding the crown/star frame
## (Assets/image/a_clean_..._fra-removebg-preview.png), drawn 9-slice so the
## corner ornaments keep their shape. Add content to root.get_meta('content').
static func frame_overlay(width: float, node_name: String) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.1, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.name = 'Frame'
	var style := StyleBoxTexture.new()
	style.texture = load(FRAME_TALL)
	style.texture_margin_left = 130
	style.texture_margin_right = 85
	style.texture_margin_top = 95
	style.texture_margin_bottom = 95
	style.content_margin_left = 56
	style.content_margin_right = 56
	style.content_margin_top = 60
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override('panel', style)
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override('separation', 6)
	panel.add_child(content)
	root.set_meta('content', content)
	# Pop in.
	panel.pivot_offset = Vector2(width * 0.5, 300)
	panel.scale = Vector2.ONE * 0.88
	panel.modulate.a = 0.0
	var tween := panel.create_tween().set_parallel()
	tween.tween_property(panel, 'scale', Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, 'modulate:a', 1.0, 0.15)
	return root

static func icon(path: String, size: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = load(path)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(size, size)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture

## Gold heading between two stars.
static func fancy_title(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override('separation', 14)
	row.add_child(icon(STAR_ICON, 34))
	var title := label(text, 40, GOLD, 10)
	title.add_theme_color_override('font_outline_color', Color(0.35, 0.12, 0.02))
	row.add_child(title)
	row.add_child(icon(STAR_ICON, 34))
	return row

## Small section heading with a line on each side.
static func section(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 10)
	for side in 2:
		var line := ColorRect.new()
		line.color = Color(0.45, 0.7, 1.0, 0.45)
		line.custom_minimum_size = Vector2(0, 2)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(line)
		if side == 0:
			row.add_child(label(text, 20, MINT, 4))
	return row

## Rounded translucent bar (like the Game Clear rows); add children to bar.get_meta('row').
static func bar(height: float = 40.0) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.2, 0.72)
	style.set_corner_radius_all(22)
	style.border_color = Color(0.3, 0.5, 0.9, 0.55)
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override('panel', style)
	panel.custom_minimum_size.y = height
	var row := HBoxContainer.new()
	row.add_theme_constant_override('separation', 12)
	panel.add_child(row)
	panel.set_meta('row', row)
	return panel

static func fancy_slider(value: float, low: float, high: float, step: float, on_change: Callable) -> HBoxContainer:
	var holder := HBoxContainer.new()
	holder.add_theme_constant_override('separation', 10)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(170, 28)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.0, 0.03, 0.12, 0.9)
	track.set_corner_radius_all(6)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(6)
	slider.add_theme_stylebox_override('slider', track)
	slider.add_theme_stylebox_override('grabber_area', fill)
	slider.add_theme_stylebox_override('grabber_area_highlight', fill)
	var star: Texture2D = load(STAR_SMALL)
	slider.add_theme_icon_override('grabber', star)
	slider.add_theme_icon_override('grabber_highlight', star)
	holder.add_child(slider)
	var amount := label('%d%%' % roundi((value - low) / (high - low) * 100.0), 18, GOLD, 4)
	amount.custom_minimum_size.x = 56
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	holder.add_child(amount)
	slider.value_changed.connect(func(v: float):
		amount.text = '%d%%' % roundi((v - low) / (high - low) * 100.0)
		on_change.call(v))
	return holder

static func fancy_toggle(on: bool, on_toggle: Callable) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.button_pressed = on
	toggle.text = 'เปิด' if on else 'ปิด'
	toggle.add_theme_font_size_override('font_size', 17)
	toggle.add_theme_color_override('font_color', GOLD if on else Color(0.7, 0.75, 0.85))
	toggle.add_theme_color_override('font_pressed_color', GOLD)
	toggle.add_theme_color_override('font_hover_pressed_color', GOLD)
	toggle.custom_minimum_size.x = 96
	toggle.toggled.connect(func(value: bool):
		toggle.text = 'เปิด' if value else 'ปิด'
		toggle.add_theme_color_override('font_color', GOLD if value else Color(0.7, 0.75, 0.85))
		on_toggle.call(value))
	return toggle

static func close_button(text: String, on_close: Callable) -> Button:
	var close := button(text, true, 240)
	close.name = 'Close'
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(on_close)
	return close

static func credits_overlay(on_close: Callable, close_text: String = 'ปิด') -> Control:
	var root := frame_overlay(760, 'Credits')
	var content: VBoxContainer = root.get_meta('content')
	content.add_child(fancy_title('เครดิต'))
	var game := label('Just go up!!  ·  กลุ่ม 4', 20, CREAM, 4)
	game.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(game)
	var course := label('CP352203 / CP410844 Computer Game Development  ·  ปีการศึกษา 2569', 15, SKY)
	course.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(course)
	content.add_child(section('ผู้จัดทำ'))
	for member in TEAM:
		var row_panel := bar(40)
		var row: HBoxContainer = row_panel.get_meta('row')
		row.add_child(icon(STAR_ICON, 24))
		var id := label(member[0], 19, GOLD, 4)
		id.custom_minimum_size.x = 150
		row.add_child(id)
		var name_label := label(member[1], 20, Color.WHITE, 4)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var major := label('  สาขา ' + member[2] + '  ', 15, Color(0.05, 0.1, 0.2))
		var chip := box(MINT, 10)
		chip.content_margin_top = 2
		chip.content_margin_bottom = 2
		chip.content_margin_left = 6
		chip.content_margin_right = 6
		major.add_theme_stylebox_override('normal', chip)
		major.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(major)
		content.add_child(row_panel)
	content.add_child(section('Asset ที่ใช้'))
	var assets := label('\n'.join(ASSET_CREDITS), 13, Color(0.8, 0.86, 0.98))
	assets.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(assets)
	var close := close_button(close_text, on_close)
	content.add_child(close)
	root.set_meta('close', close)
	return root

static func controls_list() -> GridContainer:
	# Two key/action pairs per line keeps the panel short.
	var list := GridContainer.new()
	list.columns = 2
	list.add_theme_constant_override('h_separation', 18)
	list.add_theme_constant_override('v_separation', 6)
	for entry in [['W A S D', 'เดิน'], ['Shift', 'วิ่ง'], ['Space', 'กระโดด 3 ครั้ง (ครั้งที่ 3 ตีลังกา)'],
			['เมาส์', 'หมุนกล้อง'], ['R', 'กลับไปจุดเซฟของลุงโอลี่'], ['Esc', 'หยุดเกม']]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override('separation', 12)
		var key := label(entry[0], 16, Color(0.05, 0.08, 0.2))
		var cap := box(GOLD, 8)
		cap.content_margin_top = 1
		cap.content_margin_bottom = 1
		cap.content_margin_left = 8
		cap.content_margin_right = 8
		key.add_theme_stylebox_override('normal', cap)
		key.custom_minimum_size.x = 76
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(key)
		row.add_child(label(entry[1], 16, Color.WHITE, 3))
		list.add_child(row)
	return list

static func controls_overlay(on_close: Callable) -> Control:
	var root := frame_overlay(620, 'Controls')
	var content: VBoxContainer = root.get_meta('content')
	content.add_child(fancy_title('วิธีเล่น'))
	content.add_child(controls_list())
	var close := close_button('เข้าใจแล้ว', on_close)
	content.add_child(close)
	root.set_meta('close', close)
	return root

## Settings (saved by GameManager): music and effects each have their own
## on/off switch and volume, plus mouse sensitivity, fullscreen and controls.
static func options_overlay(on_close: Callable) -> Control:
	# Looked up at runtime so UiKit compiles even where autoload names are unknown.
	var settings: Node = (Engine.get_main_loop() as SceneTree).root.get_node('GameManager')
	var root := frame_overlay(720, 'Options')
	var content: VBoxContainer = root.get_meta('content')
	content.add_child(fancy_title('ตั้งค่า'))
	content.add_child(section('เสียง'))
	for entry in [['เพลง', 'music'], ['เสียงเอฟเฟกต์', 'sfx']]:
		var kind: String = entry[1]
		var row_panel := bar()
		var row: HBoxContainer = row_panel.get_meta('row')
		var name_label := label(entry[0], 19, Color.WHITE, 4)
		name_label.custom_minimum_size.x = 130
		row.add_child(name_label)
		row.add_child(fancy_toggle(settings.get(kind + '_on'), func(on: bool):
			settings.set(kind + '_on', on)
			settings.apply_settings()))
		row.add_child(fancy_slider(settings.get(kind + '_volume'), 0.0, 1.0, 0.05, func(v: float):
			settings.set(kind + '_volume', v)
			settings.apply_settings()))
		content.add_child(row_panel)
	content.add_child(section('ควบคุม'))
	var mouse_panel := bar()
	var mouse_row: HBoxContainer = mouse_panel.get_meta('row')
	var mouse_label := label('ความไวเมาส์', 19, Color.WHITE, 4)
	mouse_label.custom_minimum_size.x = 130
	mouse_row.add_child(mouse_label)
	mouse_row.add_child(fancy_slider(settings.mouse_sensitivity, 0.04, 0.4, 0.01, func(v: float):
		settings.mouse_sensitivity = v
		for camera in Engine.get_main_loop().get_nodes_in_group('PlayerCamera'):
			camera.mouse_sensitivity = v))
	content.add_child(mouse_panel)
	if not OS.has_feature('web'):
		var screen_panel := bar()
		var screen_row: HBoxContainer = screen_panel.get_meta('row')
		var screen_label := label('เต็มจอ', 19, Color.WHITE, 4)
		screen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		screen_row.add_child(screen_label)
		screen_row.add_child(fancy_toggle(settings.fullscreen, func(on: bool):
			settings.fullscreen = on
			settings.apply_settings()))
		content.add_child(screen_panel)
	content.add_child(section('วิธีเล่น'))
	content.add_child(controls_list())
	var close := close_button('บันทึกและปิด', func():
		settings.save_settings()
		on_close.call())
	content.add_child(close)
	root.set_meta('close', close)
	return root
