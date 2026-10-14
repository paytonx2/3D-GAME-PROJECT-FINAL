extends CharacterBody3D

signal jumped(count: int)

@export_category("Aof movement")
@export var move_speed: float = 3.5
@export var run_speed: float = 6.0
@export var jump_force: float = 6.0
@export var acceleration: float = 24.0
@export var air_acceleration: float = 12.0
@export var gravity: float = 19.6
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export_range(1, 5) var jump_limit: int = 3
## Jump number (within one airborne chain) that plays the somersault.
@export var flip_on_jump: int = 3
@export_category("Food boost")
@export var boost_multiplier: float = 1.35
@onready var model = $CharacterModel
@onready var spring_arm = %Gimbal
@onready var particle_trail: CPUParticles3D = $ParticleTrail
@onready var footsteps: AudioStreamPlayer3D = $Footsteps
var floor_grace: float = 0.0
var buffered_jump: float = 0.0
var jumps_used: int = 0
var boost_time: float = 0.0
var boost_duration: float = 0.0
var controls_locked: bool = false
## Admin fly mode (Insert): no gravity, no collision.
var noclip: bool = false
const NOCLIP_SPEED := 12.0
const NOCLIP_FAST := 32.0
var sparkles: CPUParticles3D

func _ready() -> void:
	footsteps.bus = &'SFX'
	sparkles = CPUParticles3D.new()
	sparkles.name = 'BoostSparkles'
	sparkles.amount = 24
	sparkles.lifetime = 0.8
	sparkles.emitting = false
	sparkles.position.y = 0.9
	sparkles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkles.emission_sphere_radius = 0.55
	sparkles.direction = Vector3.UP
	sparkles.spread = 25.0
	sparkles.initial_velocity_min = 0.6
	sparkles.initial_velocity_max = 1.4
	sparkles.gravity = Vector3.ZERO
	sparkles.scale_amount_min = 0.04
	sparkles.scale_amount_max = 0.09
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.85, 0.3)
	mesh.material = glow
	sparkles.mesh = mesh
	add_child(sparkles)

func set_noclip(value: bool) -> void:
	noclip = value
	$CollisionShape3D.disabled = value
	velocity = Vector3.ZERO
	jumps_used = 0

func fly(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis := camera.global_basis if camera else global_basis
	var direction := basis.x * input.x + basis.z * input.y
	if Input.is_action_pressed("jump"):
		direction += Vector3.UP
	if Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C):
		direction += Vector3.DOWN
	var speed := NOCLIP_FAST if Input.is_action_pressed("sprint") else NOCLIP_SPEED
	velocity = velocity.lerp(direction.limit_length(1.0) * speed, 1.0 - exp(-10.0 * delta))
	global_position += velocity * delta
	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.5:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-10.0 * delta))
	model.animate(delta, 0.0, false, -1.0, false)
	particle_trail.emitting = false
	footsteps.stream_paused = true

func _physics_process(delta: float) -> void:
	if noclip:
		fly(delta)
		return
	var controls_active := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not controls_locked
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if controls_active else Vector2.ZERO
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	var running := controls_active and Input.is_action_pressed("sprint")
	var speed := run_speed if running else move_speed
	var rate := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction.x * speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, rate * delta)
	update_jump_state(delta)
	update_boost(delta)
	if controls_active and Input.is_action_just_pressed("jump"):
		buffered_jump = jump_buffer
	if not try_buffered_jump() and not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-14.0 * delta))
	model.animate(delta, horizontal_speed, is_on_floor(), velocity.y, running)
	particle_trail.emitting = is_on_floor() and horizontal_speed > 4.0
	footsteps.stream_paused = not (is_on_floor() and horizontal_speed > 0.3)
	footsteps.pitch_scale = 1.15 if running else 0.8

func update_jump_state(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		jumps_used = 0
		floor_grace = coyote_time
	else:
		floor_grace = maxf(0.0, floor_grace - delta)
		# Walking off an edge uses the ground jump after the grace window.
		if floor_grace == 0.0 and jumps_used == 0:
			jumps_used = 1
	buffered_jump = maxf(0.0, buffered_jump - delta)

func current_jump_force() -> float:
	return jump_force * (boost_multiplier if boost_time > 0.0 else 1.0)

func try_buffered_jump() -> bool:
	if buffered_jump <= 0.0 or jumps_used >= jump_limit:
		return false
	jumps_used += 1
	velocity.y = current_jump_force()
	floor_grace = 0.0
	buffered_jump = 0.0
	# Jumps 1-2 keep the normal jump pose; the third chained jump somersaults.
	if jumps_used == flip_on_jump and model.has_method('start_flip'):
		model.start_flip()
	AudioManager.jump_sfx.pitch_scale = 1.0 + (jumps_used - 1) * 0.08
	AudioManager.jump_sfx.play()
	jumped.emit(jumps_used)
	return true

func apply_jump_boost(duration: float) -> void:
	boost_duration = duration
	boost_time = duration
	sparkles.emitting = true

func update_boost(delta: float) -> void:
	if boost_time <= 0.0:
		return
	boost_time = maxf(0.0, boost_time - delta)
	if boost_time == 0.0:
		sparkles.emitting = false

func reset_to_spawn(spawn: Vector3) -> void:
	global_position = spawn
	velocity = Vector3.ZERO
	floor_grace = 0.0
	buffered_jump = 0.0
	jumps_used = 0
	spring_arm.snap_to_player()
