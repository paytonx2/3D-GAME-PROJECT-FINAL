extends AnimatableBody3D
## Moves a climbable object around its placed (base) transform.
## slide: back and forth along a local axis   bob: up and down
## spin: turns around the world Y axis        float: space drift (bob, sway, slow turn)
## flip: rests, then somersaults 360° around its local X axis (throws Aof off)
## rock: seesaw tilt around its local Z axis  orbit: circles around its base point

@export_enum('slide','bob','spin','float','flip','rock','orbit') var mode: String = 'slide'
@export var axis: Vector3 = Vector3.RIGHT
@export var amplitude: float = 1.5
@export var period: float = 4.0
@export var spin_speed: float = 25.0
@export var phase: float = 0.0
## flip: seconds resting flat, then seconds spent turning.
@export var hold_time: float = 3.0
@export var flip_time: float = 2.8
## Local point the flip/rock rotation turns around (the object's middle).
@export var pivot: Vector3 = Vector3.ZERO
## float: add a slow flip/rock on top of the drift ('' | 'flip' | 'rock').
@export var extra: String = ''
var base: Transform3D
var time: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	base = transform

func around_pivot(rotation: Basis) -> Transform3D:
	return Transform3D(rotation, pivot - rotation * pivot)

func flip_angle(t: float) -> float:
	var cycle := hold_time + flip_time
	var local := fposmod(t + phase / TAU * cycle, cycle)
	if local < hold_time:
		return 0.0
	var k := (local - hold_time) / flip_time
	# Sine ease: starts and ends gently instead of snapping round.
	return TAU * (0.5 - 0.5 * cos(PI * k))

func rock_angle(t: float) -> float:
	return deg_to_rad(spin_speed) * sin(t * TAU / period + phase)

func pose_at(t: float) -> Transform3D:
	var wave := sin(t * TAU / period + phase)
	match mode:
		'slide':
			return Transform3D(base.basis, base.origin + base.basis * axis.normalized() * amplitude * wave)
		'bob':
			return Transform3D(base.basis, base.origin + Vector3.UP * amplitude * wave)
		'spin':
			return Transform3D(Basis(Vector3.UP, deg_to_rad(spin_speed) * t) * base.basis, base.origin)
		'flip':
			return base * around_pivot(Basis(Vector3.RIGHT, flip_angle(t)))
		'rock':
			return base * around_pivot(Basis(Vector3.FORWARD, rock_angle(t)))
		'orbit':
			var angle := t * TAU / period + phase
			return Transform3D(base.basis, base.origin + Vector3(cos(angle), 0, sin(angle)) * amplitude - Vector3(cos(phase), 0, sin(phase)) * amplitude)
		'float':
			var sway := cos(t * TAU / (period * 1.7) + phase) * amplitude * 0.5
			var turn := Basis(Vector3.UP, deg_to_rad(spin_speed) * sin(t * TAU / (period * 3.0) + phase))
			var drift := Transform3D(turn * base.basis, base.origin + Vector3(sway, amplitude * wave, 0))
			if extra == 'flip':
				return drift * around_pivot(Basis(Vector3.RIGHT, flip_angle(t)))
			if extra == 'rock':
				return drift * around_pivot(Basis(Vector3.FORWARD, deg_to_rad(18.0) * sin(t * TAU / (period * 0.8) + phase)))
			return drift
	return base

func _physics_process(delta: float) -> void:
	time += delta
	transform = pose_at(time)
