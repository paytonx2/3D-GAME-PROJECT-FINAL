extends Area3D
## The Star of Wishes at the summit. Touching it ends the climb.

var claimed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if claimed or not body.is_in_group('Player'):
		return
	claimed = true
	var level := get_tree().get_first_node_in_group('Level')
	if level and level.has_method('finish_game'):
		level.finish_game()
