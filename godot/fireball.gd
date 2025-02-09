extends Area3D

var velocity := Vector3.ZERO
@onready var sprite_3d: Sprite3D = $Sprite3D

func _process(delta: float) -> void:
	if GameState.hitstun or GameState.malfunction: return
	global_position += velocity * delta


func _on_change_sprite_timeout() -> void:
	sprite_3d.flip_h = randf() < 0.5
	sprite_3d.flip_v = randf() < 0.5
	
	


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("onhit"):
		body.onhit()
	queue_free()
