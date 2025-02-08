extends CharacterBody3D

@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var camera_3d: Camera3D = %Camera3D

const SPEED = 5.0
const MOUSE_SENS = 0.5
const BOB_MAGNITUDE = 0.05
const BOB_FREQ = 2.0

var bob_speed := 0.0
var bob_t := 0.0
var can_shoot = true
var dead = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(shoot_anim_done)
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)
	
func _input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	
	if dead: return
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
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
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("onhit"):
		ray_cast_3d.get_collider().call("onhit")

func shoot_anim_done():
	can_shoot = true
	
func restart():
	get_tree().reload_current_scene()

func onhit():
	dead = true
	$CanvasLayer/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	
