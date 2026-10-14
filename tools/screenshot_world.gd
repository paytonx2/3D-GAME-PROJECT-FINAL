extends SceneTree
## Renders the world from fixed viewpoints: godot --path . --script res://tools/screenshot_world.gd -- <out_dir>

func _initialize() -> void:
	call_deferred('run')

func shot(world: Node3D, camera: Camera3D, from: Vector3, to: Vector3, path: String) -> void:
	camera.position = from
	camera.look_at(to)
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(path)
	print('saved ', path)

func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var world: Node3D = load('res://Scenes/world.tscn').instantiate()
	world.cinematic = true
	root.add_child(world)
	var camera := Camera3D.new()
	camera.fov = 60
	camera.far = 2000
	world.add_child(camera)
	camera.current = true
	var p := world.get_node('Platforms')
	var cp := world.get_node('Checkpoints')
	var spawn: Vector3 = cp.get_child(0).global_position
	await shot(world, camera, spawn + Vector3(-4, 2.2, 6), spawn + Vector3(0, 2.5, -12), out + '/01_start.png')
	await shot(world, camera, Vector3(30, 22, 30), Vector3(-8, 8, -16), out + '/02_plaza_overview.png')
	await shot(world, camera, Vector3(8, 4, 2), Vector3(-10, 14, -24), out + '/03_zone1_lookup.png')
	var z2: Vector3 = cp.get_child(1).global_position
	await shot(world, camera, z2 + Vector3(5, 3, 8), z2 + Vector3(0, 1, 0), out + '/04_zone2_oli.png')
	await shot(world, camera, z2 + Vector3(12, 8, 12), z2 + Vector3(-4, 14, -8), out + '/05_zone2_route.png')
	var z3: Vector3 = cp.get_child(2).global_position
	await shot(world, camera, z3 + Vector3(5, 3, 8), z3 + Vector3(0, 1, 0), out + '/06_zone3_oli.png')
	await shot(world, camera, z3 + Vector3(14, 6, 14), z3 + Vector3(-4, 14, -8), out + '/07_zone3_route.png')
	var summit: Node3D = p.get_node('Summit')
	await shot(world, camera, summit.global_position + Vector3(5, 4, 8), summit.global_position + Vector3(0, 1.5, -1), out + '/08_summit.png')
	quit()
