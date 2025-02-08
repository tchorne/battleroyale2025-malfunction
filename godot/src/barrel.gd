extends StaticBody3D

var damaged = false
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var particles: GPUParticles3D = $Particles

func _process(_delta: float) -> void:
	particles.process_mode = Node.PROCESS_MODE_DISABLED if GameState.hitstun else Node.PROCESS_MODE_INHERIT
	
func onhit():
	if !damaged:
		$Damaged.play()
		animated_sprite_3d.play("damaged")
		damaged = true
	elif damaged:
		$CollisionShape3D.disabled = true
		$Particles.restart()
		$Explode.play()
		get_tree().create_timer(0.1).timeout.connect(damage)

func damage():
	var hitcount := 0
	for body in $Explosion.get_overlapping_bodies():
		if body.is_in_group("Barrel"): continue
		if body.has_method("onhit"):
			body.onhit()
			hitcount += 1
	GameState.begin_hitstun(0.3 + 0.1 * hitcount)
	queue_free()
