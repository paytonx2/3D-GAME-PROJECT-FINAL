extends Node
## Integration test for Scenes/world.tscn using Aof's real capsule and movement values.
##   godot --headless --path . --scene res://tests/world_test.tscn --log-file ./world-test.log

var failures: Array[String] = []
var level: Node3D
var player
var space: PhysicsDirectSpaceState3D
var last_floor := ''
var trace := false
var failed_main: Array = []
var failed_side: Array = []
const DT := 1.0 / 60.0

func check(ok: bool, message: String) -> void:
	print(('PASS: ' if ok else 'FAIL: ') + message)
	if not ok:
		failures.append(message)

func frame() -> void:
	await get_tree().physics_frame
	player.update_jump_state(DT)
	player.update_boost(DT)
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * DT
	player.move_and_slide()
	player.model.animate(DT, 0.0, player.is_on_floor(), player.velocity.y, false)

func settle(position: Vector3) -> void:
	player.reset_to_spawn(position)
	player.velocity.y = -0.1
	player.move_and_slide()
	for i in range(25):
		await frame()
	await get_tree().physics_frame

func ground(point: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 3.0, point + Vector3.DOWN * 4.0, 1, [player.get_rid()])
	return space.intersect_ray(query)

## Runs from source toward target and chains up to three jumps, braking in the air.
func attempt(source: Node3D, target: Node3D) -> bool:
	var origin: Vector3 = source.get_meta('landing')
	var destination: Vector3 = target.get_meta('landing')
	var flat := Vector3(destination.x - origin.x, 0, destination.z - origin.z)
	var direction := flat.normalized()
	var half: float = source.get_meta('half_depth')
	# Take off from the standable point of the source closest to the target.
	var takeoff := {}
	var best := INF
	var reach := half + 0.5
	var source_basis: Basis = source.global_basis
	for gx in range(-8, 9):
		for gz in range(-12, 13):
			var local := Vector3(gx / 8.0 * reach, 0, gz / 12.0 * reach)
			var point := origin + source_basis * local
			var hit := ground(point)
			if hit.is_empty() or hit.collider != source or hit.normal.y < 0.85:
				continue
			# Keep a margin from the edge: all four neighbours must be standable too.
			var safe := true
			for offset in [Vector3(0.3, 0, 0), Vector3(-0.3, 0, 0), Vector3(0, 0, 0.3), Vector3(0, 0, -0.3)]:
				var near := ground(hit.position + offset)
				if near.is_empty() or near.collider != source:
					safe = false
					break
			if not safe:
				continue
			var distance := Vector2(destination.x - hit.position.x, destination.z - hit.position.z).length()
			if distance < best:
				best = distance
				takeoff = hit
	if takeoff.is_empty():
		return false
	direction = Vector3(destination.x - takeoff.position.x, 0, destination.z - takeoff.position.z).normalized()
	await settle(takeoff.position + Vector3.UP * 0.03)
	if not player.is_on_floor():
		return false
	player.velocity = direction * player.run_speed
	player.buffered_jump = player.jump_buffer
	player.try_buffered_jump()
	for k in range(200):
		await get_tree().physics_frame
		player.update_jump_state(DT)
		var jumped := false
		var below_target: bool = player.global_position.y < destination.y + 0.4
		if not player.is_on_floor() and player.velocity.y < 0.4 and below_target and player.jumps_used < player.jump_limit:
			player.buffered_jump = player.jump_buffer
			jumped = player.try_buffered_jump()
		if not jumped and not player.is_on_floor():
			player.velocity.y -= player.gravity * DT
		var to_target := Vector3(destination.x - player.global_position.x, 0, destination.z - player.global_position.z)
		var remaining := to_target.length()
		var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
		var stop: float = speed * speed / (2.0 * player.air_acceleration)
		# Wait below the target height before crossing over its edge.
		# Wait for height only when the target's side is right in front of Aof.
		var too_low := false
		if remaining > 0.05 and player.global_position.y < destination.y - 0.15:
			var ahead := ground(player.global_position + to_target.normalized() * 0.7 + Vector3.UP * 1.0)
			too_low = not ahead.is_empty() and ahead.collider == target and ahead.position.y > player.global_position.y + 0.05
		var desired: Vector3 = Vector3.ZERO if remaining <= stop + 0.05 or too_low else to_target.normalized() * player.run_speed
		player.velocity.x = move_toward(player.velocity.x, desired.x, player.air_acceleration * DT)
		player.velocity.z = move_toward(player.velocity.z, desired.z, player.air_acceleration * DT)
		player.move_and_slide()
		if trace and k % 5 == 0:
			print('   k=%d pos=%s vel=%s floor=%s used=%d' % [k, player.global_position, player.velocity, player.is_on_floor(), player.jumps_used])
		if player.is_on_floor():
			for c in player.get_slide_collision_count():
				var hit_body: Object = player.get_slide_collision(c).get_collider()
				last_floor = str(hit_body.get_path()) if hit_body is Node else str(hit_body)
				if hit_body == target:
					return true
			if k > 10 and player.global_position.y < origin.y - 0.5:
				return false
		if player.global_position.y < origin.y - 6.0:
			return false
	return false

func _ready() -> void:
	level = load('res://Scenes/world.tscn').instantiate()
	add_child(level)
	# Freeze movers at their placed pose before any physics step runs.
	var movers := 0
	for body in level.get_node('Platforms').get_children() + level.get_node('SidePlatforms').get_children():
		if body is AnimatableBody3D:
			movers += 1
			body.set_physics_process(false)
	player = level.get_node('Player')
	player.set_physics_process(false)
	level.set_physics_process(false)
	await get_tree().physics_frame
	space = level.get_world_3d().direct_space_state
	var checkpoints: Node3D = level.get_node('Checkpoints')
	check(checkpoints.get_child_count() == 3, 'One Uncle Oli save point per zone')
	for cp in checkpoints.get_children():
		check(cp.get_node_or_null('UncleOli/Asset') != null, 'UncleOli model stands at ' + str(cp.name))
		check(cp.get_node_or_null('Ring') == null, 'Old ring marker removed at ' + str(cp.name))
	check(level.get_meta('zone_heights').size() == 3, 'Three zones are defined')
	check(level.has_node('StartArea/Tiles') and level.get_node('StartArea/Tiles').get_child_count() == 25, 'Start plaza uses KayKit city tiles')
	var foods := get_tree().get_nodes_in_group('Food')
	check(foods.size() >= 9, 'Food pickups are placed along the route (%d)' % foods.size())
	check(movers >= 60, 'Many climbable objects move (%d)' % movers)
	var zone3_still := 0
	for body in level.get_node('Platforms').get_children() + level.get_node('SidePlatforms').get_children():
		if body.get_meta('zone') == 2 and body.get_meta('kind') not in ['dock', 'summit'] and not (body is AnimatableBody3D):
			zone3_still += 1
	check(zone3_still == 0, 'Every space-zone object floats')
	# Start and jumping rules.
	await settle(level.respawn_position)
	check(player.is_on_floor(), 'Start plaza has a safe landing surface')
	var model = player.get_node('CharacterModel')
	for jump in range(3):
		player.buffered_jump = player.jump_buffer
		check(player.try_buffered_jump(), 'Jump %d fires' % (jump + 1))
		check(model.is_flipping() == (jump == 2), 'Jump %d %s' % [jump + 1, 'somersaults' if jump == 2 else 'has no somersault'])
		for i in range(18):
			await frame()
	player.buffered_jump = player.jump_buffer
	check(not player.try_buffered_jump(), 'Fourth consecutive jump is blocked')
	for i in range(100):
		await frame()
	check(player.is_on_floor() and player.jumps_used == 0, 'Landing restores three jumps')
	check(not model.is_flipping(), 'Somersault finishes by landing')
	# Food boost.
	var food: Area3D = foods[0]
	var normal_force: float = player.current_jump_force()
	food._on_body_entered(player)
	check(player.boost_time > 0.0 and player.current_jump_force() > normal_force * 1.3, 'Food raises jump power temporarily')
	check(not food.visual.visible, 'Eaten food disappears')
	for i in range(int(player.boost_duration / DT) + 5):
		player.update_boost(DT)
	check(player.current_jump_force() == normal_force, 'Food boost wears off')
	# Save points.
	level.set_physics_process(true)
	await settle(checkpoints.get_child(1).get_node('Spawn').global_position)
	await get_tree().physics_frame
	check(level.active_checkpoint == 1, 'Standing by Uncle Oli saves zone 2')
	await settle(checkpoints.get_child(2).get_node('Spawn').global_position)
	await get_tree().physics_frame
	check(level.active_checkpoint == 2, 'Standing by Uncle Oli saves zone 3')
	check(int(GameManager.load_progress().get('checkpoint', -1)) == 2, 'Save point is written for Continue')
	level.set_physics_process(false)
	await settle(checkpoints.get_child(0).get_node('Spawn').global_position)
	check(level.active_checkpoint == 2, 'Returning to an older save point keeps progress')
	level.set_physics_process(true)
	var falls_before: int = level.falls
	player.reset_to_spawn(level.respawn_position + Vector3(30, -20, 0))
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(level.falls == falls_before + 1 and player.global_position.distance_to(level.respawn_position) < 0.3, 'Falling far below respawns at the latest save point')
	# Admin no-clip flight.
	player.set_noclip(true)
	check(player.get_node('CollisionShape3D').disabled, 'No clip disables collision')
	var falls_now: int = level.falls
	player.global_position = level.respawn_position + Vector3(0, -60, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(level.falls == falls_now, 'Flying below the map does not count as a fall')
	player.set_noclip(false)
	check(not player.get_node('CollisionShape3D').disabled, 'No clip off restores collision')
	player.reset_to_spawn(level.respawn_position)
	level.set_physics_process(false)
	# Reachability of every step with plain jumps (no food).
	player.boost_time = 0.0
	var route: Array[Node] = level.get_node('Platforms').get_children()
	check(route.size() >= 110, 'Route has %d climbable steps' % route.size())
	var rises: Array[float] = []
	for i in range(route.size() - 1):
		var a: Vector3 = route[i].get_meta('landing')
		var b: Vector3 = route[i + 1].get_meta('landing')
		if a.y > 0.5:
			rises.append(b.y - a.y)
		var ok := await attempt(route[i], route[i + 1])
		check(ok, '%s -> %s reachable (rise %.1f m)' % [route[i].name, route[i + 1].name, b.y - a.y])
		if not ok:
			failed_main.append(str(route[i + 1].name))
		if not ok:
			print('  ended at ', player.global_position, ' target ', b, ' last floor ', last_floor)
	var average := 0.0
	for r in rises:
		average += r
	average /= rises.size()
	# Side routes: every side stone can be reached and leads back to the main climb.
	var sides: Array[Node] = level.get_node('SidePlatforms').get_children()
	check(sides.size() >= 70, 'Many side stones offer other ways up (%d)' % sides.size())
	var skips := 0
	for side in sides:
		var from: Node3D = level.get_node(side.get_meta('parent'))
		var to: Node3D = level.get_node(side.get_meta('link'))
		var in_ok := await attempt(from, side)
		check(in_ok, '%s -> %s (side) reachable' % [from.name, side.name])
		if not in_ok:
			failed_side.append(str(side.name))
		if not in_ok:
			print('  ended at ', player.global_position, ' target ', side.get_meta('landing'), ' last floor ', last_floor)
		var out_ok := await attempt(side, to)
		check(out_ok, '%s -> %s (rejoin) reachable' % [side.name, to.name])
		if not out_ok and not failed_side.has(str(side.name)):
			failed_side.append(str(side.name))
		if not out_ok:
			print('  ended at ', player.global_position, ' target ', to.get_meta('landing'), ' last floor ', last_floor)
		if int(side.get_meta('skips')) > 0:
			skips += 1
	var report := FileAccess.open('res://tests/world_failures.json', FileAccess.WRITE)
	report.store_string(JSON.stringify({'main': failed_main, 'side': failed_side}, '	'))
	report.close()
	check(skips >= 5, 'Some side routes skip main steps (%d)' % skips)
	check(average > 1.4, 'Course climbs steeply (average rise %.2f m per step)' % average)
	# Reaching the star ends the game.
	level.set_physics_process(true)
	var star: Area3D = level.get_node('Platforms/Summit/WishStar')
	# The summit jump may already have touched the star; replay it from a fresh save.
	star.claimed = false
	level.finished = false
	GameManager.save_progress({'checkpoint': 2})
	star._on_body_entered(player)
	check(level.finished, 'Star of Wishes finishes the climb')
	check(not GameManager.has_progress(), 'Finishing clears the Continue save')
	var modes := {}
	for body in route:
		if body is AnimatableBody3D:
			var key: String = body.mode + ('+' + body.extra if body.extra != '' else '')
			modes[key] = modes.get(key, 0) + 1
	print('Motion mix: ', modes)
	check(modes.has('flip') and modes.has('rock') and modes.has('orbit') and modes.has('float+flip'), 'Somersaulting, seesaw and orbiting platforms exist')
	check(level.has_node('Platforms/Summit/StarKeeper/Asset'), 'Star Keeper uses the StarKeeper model')
	print('WORLD TESTS: %s' % ('ALL PASSED' if failures.is_empty() else str(failures.size()) + ' FAILED'))
	get_tree().quit(0 if failures.is_empty() else 1)
