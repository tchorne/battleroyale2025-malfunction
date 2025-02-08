extends CharacterBody3D

@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var jammed_sound: AudioStreamPlayer = $JammedSound
@onready var camera_3d: Camera3D = %Camera3D
@onready var ammo_count: Label = $CanvasLayer/GunBase/AmmoCount
@onready var weapon_anim: AnimationPlayer = $WeaponAnim

const SPEED = 5.0
const MOUSE_SENS = 0.5
const BOB_MAGNITUDE = 0.05
const BOB_FREQ = 2.0
const HIT_INVULN = 1.0

var bob_speed := 0.0
var bob_t := 0.0
var can_shoot = true
var dead = false
var gun_jammed := 0
var jam_next_shot := false
var ammo := 12
var play_reload_sound := false

var health := 100
var max_health := 100
var invulnerable := false
var post_hit_invulnerable := 0.0
var melee_invulnerable := 0.0



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(anim_finished)
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)
	update_ui()
	
func anim_finished():
	if animated_sprite_2d.animation == "shoot":
		shoot_anim_done()
	elif animated_sprite_2d.animation == "jam":
		animated_sprite_2d.play("idle")
		can_shoot = true
	
func _input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		

func _process(delta: float) -> void:
	invulnerable = false
	if post_hit_invulnerable > 0:
		invulnerable = true
		post_hit_invulnerable -= delta
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	
	if dead: return
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	if Input.is_action_just_pressed("melee"):
		melee()
	
	bob_speed = lerp(bob_speed, velocity.length(), delta*10)
	#print(bob_speed)
	#bob_speed = 2.0
	bob_t += bob_speed * delta
	camera_3d.position.y = sin(bob_t * BOB_FREQ) * BOB_MAGNITUDE

func _physics_process(_delta: float) -> void:
	if dead:
		return


	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.y = 0
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func shoot():
	if !can_shoot:
		return
	can_shoot = false
	if jam_next_shot:
		gun_jammed = true
		update_ui()
	if gun_jammed:
		jammed_sound.play()
		animated_sprite_2d.play("jam")
		return
		
	ammo -= 1
	if ammo % 4 == 0:
		jam_next_shot = true
	
	update_ui()
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("onhit"):
		ray_cast_3d.get_collider().call("onhit")

func melee():
	if can_shoot == false:
		return
	weapon_anim.play("melee")
	
	

func update_ui():
	$CanvasLayer/Health/HealthCount.text = str(health)
	ammo_count.text = str(ammo)
	ammo_count.add_theme_color_override("font_color", Color("ee0817") if not gun_jammed and ammo > 0 else Color("8a8a8a"))

func shoot_anim_done():
	can_shoot = true
	
func restart():
	get_tree().reload_current_scene()

func punch_active():
	var bodies = $PunchArea.get_overlapping_bodies()
	var enemies_hit := 0
	for body in bodies:
		if body == self: continue
		if body.has_method("onhit"):
			body.call("onhit")
			enemies_hit += 1
	
	if enemies_hit > 0:
		if gun_jammed:
			gun_jammed = false
			play_reload_sound = true
	update_ui()

func reload_sound():
	if play_reload_sound:
		$Unjam.play()
		play_reload_sound = false
	

func onhit():
	if invulnerable:
		return
		
	health -= 10
	post_hit_invulnerable = HIT_INVULN
	update_ui()
	if health <= 0:
		dead = true
		health = 0
		$CanvasLayer/DeathScreen.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	
