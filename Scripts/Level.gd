extends Node3D

# ---------- FUNCTIONS ---------- #

func _ready():
	var coins = get_node_or_null("Coins")
	GameManager.reset_level(coins.get_child_count() if coins else 0)
