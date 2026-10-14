extends Node3D
## Non-solid scenery that hovers and turns slowly (clouds, ships, the wish star).

@export var bob_amplitude: float = 0.4
@export var bob_period: float = 5.0
@export var spin_speed: float = 6.0
@export var drift: Vector3 = Vector3.ZERO
@export var drift_period: float = 30.0
@export var phase: float = 0.0
## Extra tumbling in degrees per second around X/Y/Z (space rocks).
@export var tumble: Vector3 = Vector3.ZERO
var base := Vector3.ZERO
var time: float = 0.0

func _ready() -> void:
	base = position

func _process(delta: float) -> void:
	time += delta
	var bob := sin(time * TAU / bob_period + phase) * bob_amplitude
	var wander := drift * sin(time * TAU / drift_period + phase)
	position = base + Vector3.UP * bob + wander
	rotate_y(deg_to_rad(spin_speed) * delta)
	if tumble != Vector3.ZERO:
		rotate_x(deg_to_rad(tumble.x) * delta)
		rotate_z(deg_to_rad(tumble.z) * delta)
