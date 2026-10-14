extends SceneTree
## Captures menu, credits, story and in-game HUD: godot --path . --script res://tools/screenshot_ui.gd -- <out_dir>
var out := ''

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	call_deferred('run')

func wait(frames: int) -> void:
	for i in frames:
		await process_frame

func snap(name: String) -> void:
	await wait(3)
	root.get_texture().get_image().save_png(out + '/' + name + '.png')
	print('saved ', name)

func run() -> void:
	change_scene_to_file('res://Scenes/main_menu.tscn')
	await wait(90)
	await snap('ui_01_menu')
	current_scene.credits_button.pressed.emit()
	await snap('ui_02_credits')
	current_scene.close_popup()
	change_scene_to_file('res://Scenes/story.tscn')
	await wait(200)
	await snap('ui_03_story_p1')
	for i in 3:
		current_scene.text_label.visible_ratio = 1.0
		current_scene.next_page()
	await wait(240)
	await snap('ui_04_story_p4')
	change_scene_to_file('res://Scenes/world.tscn')
	await wait(60)
	var world = current_scene
	var player = world.get_node('Player')
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await wait(30)
	await snap('ui_05_hud_start')
	# Chain three jumps; capture the third one mid-somersault.
	for jump in 3:
		player.buffered_jump = player.jump_buffer
		for i in (18 if jump < 2 else 12):
			await physics_frame
	await snap('ui_06_flip')
	player.apply_jump_boost(10.0)
	world.on_food_eaten(get_first_node_in_group('Food'))
	await wait(80)
	await snap('ui_07_boost')
	quit()
