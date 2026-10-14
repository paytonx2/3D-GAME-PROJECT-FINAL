extends Area3D
## One save point per zone: Uncle Oli stands here, greets Aof and saves progress.

@export var checkpoint_index: int = 0
@export var zone_name: String = ''
@export var greeting: String = 'สวัสดี Aof!'
@export_multiline var message: String = ''
@onready var spawn: Marker3D = $Spawn
@onready var oli: Node3D = $UncleOli
@onready var bubble: Label3D = $Bubble
@onready var glow: OmniLight3D = $Glow
var active: bool = false
var time: float = 0.0
var oli_base := Vector3.ZERO

func _ready() -> void:
	oli_base = oli.position
	time = checkpoint_index * 1.3
	bubble.text = greeting
	bubble.visible = false

func _physics_process(delta: float) -> void:
	time += delta
	# Gentle idle: Oli breathes and sways in place.
	oli.position.y = oli_base.y + absf(sin(time * 2.2)) * 0.06
	oli.rotation.z = sin(time * 1.1) * 0.05
	var player: Node3D = get_tree().get_first_node_in_group('Player')
	if player == null:
		return
	var offset: Vector3 = player.global_position - oli.global_position
	var near := Vector2(offset.x, offset.z).length() < 9.0 and absf(offset.y) < 5.0
	bubble.visible = near
	if near:
		var facing := atan2(offset.x, offset.z)
		oli.rotation.y = lerp_angle(oli.rotation.y, facing, 1.0 - exp(-4.0 * delta))
	for body in get_overlapping_bodies():
		if body.is_in_group('Player') and body.is_on_floor():
			var level := get_tree().get_first_node_in_group('Level')
			if level:
				level.activate_checkpoint(self)

func set_active(value: bool) -> void:
	active = value
	glow.light_color = Color(0.45, 1.0, 0.7) if active else Color(1.0, 0.75, 0.4)
	glow.light_energy = 2.2 if active else 0.9
	if active:
		bubble.text = 'บันทึกแล้ว! ' + greeting
