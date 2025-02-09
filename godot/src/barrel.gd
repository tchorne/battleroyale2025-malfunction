extends StaticBody3D

var damaged = false
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var particles: GPUParticles3D = $Particles

var exploded := false

func _ready() -> void:
	$SpawnParticles.restart()

func _process(_delta: float) -> void:
	particles.process_mode = Node.PROCESS_MODE_DISABLED if GameState.hitstun else Node.PROCESS_MODE_INHERIT
	
func onhit():
	if exploded: return
	if !damaged:
		$Damaged.play()
		animated_sprite_3d.play("damaged")
		damaged = true
	elif damaged:
		exploded = true
		$Particles.restart()
		$Explode.play()
		get_tree().create_timer(0.1).timeout.connect(damage)

func damage():
	var hitcount := 0
	$CollisionShape3D.disabled = true
	for body in $Explosion.get_overlapping_areas():
		if body.is_in_group("Barrel"): continue
		if body.has_method("onhit"):
			body.onhit()
			hitcount += 1
	GameState.begin_hitstun(0.4 + 0.2 * min(3,hitcount))
	animated_sprite_3d.visible = false
	$Despawner.despawn(5.0)
