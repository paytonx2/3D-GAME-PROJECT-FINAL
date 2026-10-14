extends Area3D
## Food that lets Aof jump higher for a while. It grows back so a fall
## does not leave the player without help.

@export var boost_duration: float = 10.0
@export var respawn_delay: float = 20.0
@export var food_name: String = 'อาหาร'
@onready var visual: Node3D = $Visual
var time: float = 0.0
var hidden_time: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	base_y = visual.position.y
	time = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta
	visual.rotation.y += delta * 1.6
	visual.position.y = base_y + sin(time * 2.4) * 0.15
	if hidden_time > 0.0:
		hidden_time -= delta
		if hidden_time <= 0.0:
			visual.visible = true
			set_deferred('monitoring', true)

func _on_body_entered(body: Node3D) -> void:
	if not visual.visible or not body.has_method('apply_jump_boost'):
		return
	body.apply_jump_boost(boost_duration)
	AudioManager.coin_sfx.play()
	visual.visible = false
	set_deferred('monitoring', false)
	hidden_time = respawn_delay
	var level := get_tree().get_first_node_in_group('Level')
	if level and level.has_method('on_food_eaten'):
		level.on_food_eaten(self)
