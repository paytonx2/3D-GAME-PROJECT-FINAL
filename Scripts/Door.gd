extends Area3D

# ---------- VARIABLES ---------- #

@export_category("Properties")
@export var next_level: String = ""
@export var require_all_coins: bool = false

# ---------- FUNCTIONS ---------- #

func _process(delta):
	rotate_y(deg_to_rad(20) * delta)

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return
	if next_level == "":
		return
	if require_all_coins and GameManager.score < GameManager.coins_required:
		return

	get_tree().change_scene_to_file(next_level)
