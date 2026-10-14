extends SceneTree
## Menu -> story -> world flow.
##   godot --headless --path . --script res://tests/menu_flow_test.gd
var failures := 0

func _initialize() -> void:
	call_deferred('run')

func check(value: bool, description: String) -> void:
	print(('PASS: ' if value else 'FAIL: ') + description)
	if not value:
		failures += 1

func settle(frames: int = 4) -> void:
	for i in frames:
		await process_frame

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
		await process_frame

func gm() -> Node:
	return root.get_node('GameManager')

func run() -> void:
	gm().clear_progress()
	check(change_scene_to_file('res://Scenes/main_menu.tscn') == OK, 'Menu loads')
	await settle(40)
	var menu = current_scene
	check(menu.play_button.has_focus(), 'Start has keyboard focus')
	check(menu.background.texture.resource_path.ends_with('Just_GO_UP.png'), 'Poster background is used')
	check(menu.continue_button.disabled, 'Continue is disabled without a save')
	for button in [menu.play_button, menu.continue_button, menu.options_button, menu.credits_button, menu.quit_button]:
		check(Rect2(Vector2.ZERO, menu.get_viewport_rect().size).encloses(button.get_global_rect()), 'Button fits screen: ' + str(button.name))
		check(button.texture_normal != null and button.texture_hover != null, 'Button has artwork: ' + str(button.name))
	menu.credits_button.pressed.emit()
	await settle()
	var credits: Control = menu.popup
	check(credits != null and credits.name == 'Credits', 'Credits open from the menu')
	var text := ''
	for label in credits.find_children('*', 'Label', true, false):
		text += label.text + '
'
	for member in ['663380034-6', 'ณัฐดนัย สมสวย', '663380534-6', 'วรพันธุ์ คำทะเนตร', '663380285-1', 'ภควัต ชมดง', '663380532-0', 'ภูวรินทร์ ไชยพิมูล']:
		check(text.contains(member), 'Credits list ' + member)
	credits.get_meta('close').pressed.emit()
	await settle()
	check(menu.popup == null, 'Credits close')
	menu.options_button.pressed.emit()
	await settle()
	check(menu.popup != null and menu.popup.name == 'Options', 'Options open')
	menu.close_popup()
	# Continue with a save resumes at that Uncle Oli.
	gm().save_progress({'checkpoint': 1, 'elapsed': 90.0, 'falls': 3, 'foods': 2})
	change_scene_to_file('res://Scenes/main_menu.tscn')
	await settle(10)
	check(not current_scene.continue_button.disabled, 'Continue is enabled with a save')
	current_scene.continue_button.pressed.emit()
	await settle(10)
	var world = current_scene
	check(world.name == 'World' and world.active_checkpoint == 1 and world.falls == 3, 'Continue resumes at the zone 2 save point')
	var spawn: Vector3 = world.get_node('Checkpoints').get_child(1).get_node('Spawn').global_position
	check(world.player.global_position.distance_to(spawn) < 1.5, 'Aof starts next to Uncle Oli of zone 2')
	gm().clear_progress()
	change_scene_to_file('res://Scenes/main_menu.tscn')
	await settle(10)
	menu = current_scene
	menu.play_button.pressed.emit()
	await settle()
	check(current_scene.name == 'Story', 'Start opens the story intro')
	var story = current_scene
	check(story.title_label.text != '' and story.page == 0, 'First story page shows')
	# Press real keys through every page, as a player would.
	for press in 20:
		if current_scene != story:
			break
		await key(KEY_SPACE)
	await settle()
	check(current_scene.name == 'World' and not current_scene.cinematic, 'Pressing Space through the story leads into the climb')
	check(current_scene.has_node('Player'), 'Aof is playable in the world')
	# Esc skips the story.
	change_scene_to_file('res://Scenes/story.tscn')
	await settle()
	await key(KEY_ESCAPE)
	await settle()
	check(current_scene.name == 'World', 'Esc skips the story')
	print('MENU FLOW TESTS: %s' % ('ALL PASSED' if failures == 0 else str(failures) + ' FAILED'))
	quit(0 if failures == 0 else 1)
