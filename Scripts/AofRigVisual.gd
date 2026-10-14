extends Node3D
## Plays the skeletal animation clips imported with Aof_Rigged.glb.
## A somersault is layered on top by spinning the rig around its hips.
const FLIP_TIME := 0.55
const PIVOT_HEIGHT := 0.95
@onready var rig: Node3D = $Rig
@onready var animation: AnimationPlayer = $Rig/AnimationPlayer
var flip_time: float = -1.0

func _ready() -> void:
	for clip in ['Idle','Walk','Run']:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play('Idle')

func start_flip() -> void:
	flip_time = 0.0
	animation.play('Jump',0.05)

func is_flipping() -> bool:
	return flip_time >= 0.0

func apply_flip(delta: float, grounded: bool) -> void:
	var angle := 0.0
	if flip_time >= 0.0:
		flip_time += delta
		var t := clampf(flip_time / FLIP_TIME, 0.0, 1.0)
		# Ease in-out so the tuck reads clearly at the top of the rotation.
		# Positive X rotation tips the head toward +Z, Aof's facing: a front flip.
		angle = TAU *(t * t * (3.0 - 2.0 * t))
		if t >= 1.0 or (grounded and flip_time > 0.1):
			flip_time = -1.0
			angle = 0.0
	var pivot := Vector3.UP * PIVOT_HEIGHT
	rig.transform = Transform3D(Basis(Vector3.RIGHT, angle), pivot - Basis(Vector3.RIGHT, angle) * pivot)

func animate(delta: float, speed: float, grounded: bool, vertical_speed: float, running: bool) -> void:
	apply_flip(delta, grounded)
	var clip := 'Idle'
	if not grounded:
		clip = 'Jump' if vertical_speed > 0.0 or is_flipping() else 'Fall'
	elif speed > 0.15:
		clip = 'Run' if running else 'Walk'
	if animation.current_animation != clip:
		animation.play(clip,0.12)
	animation.speed_scale = clampf(speed / (3.5 if running else 1.8),0.25,2.2) if clip in ['Walk','Run'] else 1.0
