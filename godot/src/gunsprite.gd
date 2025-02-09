extends AnimatedSprite2D

func _process(delta: float) -> void:
	speed_scale = 1.5 if GameState.malfunction else 1.0
