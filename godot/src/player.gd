extends CharacterBody3D

@onready var animated_sprite_2d: AnimatedSprite2D = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var jammed_sound: AudioStreamPlayer = $JammedSound
@onready var camera_3d: Camera3D = %Camera3D
@onready var ammo_count: Label = $CanvasLayer/GunBase/AmmoCount
@onready var weapon_anim: AnimationPlayer = $WeaponAnim
@onready var hitstun_overlay: ColorRect = $CanvasLayer/Fullscreen/Hitstun
@onready var malfunction_overlay: ColorRect = $CanvasLayer/Fullscreen/Malfunction
@onready var tutorial_anim: AnimationPlayer = $CanvasLayer/Tutorial/TutorialAnim

const SPEED = 7.0
const MOUSE_SENS = 0.2
const BOB_MAGNITUDE = 0.05
const BOB_FREQ = 2.0
const HIT_INVULN = 1.0
const MELEE_INVULN = 0.5


var bob_speed := 0.0
var bob_t := 0.0
var can_shoot = true
var dead = false
var gun_jammed := 0
var shots_until_jam := 4
var jam_next_shot := false
var ammo := 12
var play_reload_sound := false

var health := 100
var max_health := 100
var invulnerable := false
var post_hit_invulnerable := 0.0
var melee_invulnerable := 0.0

var tutorial_step := 0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(anim_finished)
	#weapon_anim.animation_finished.connect()
	$CanvasLayer/DeathScreen/Panel/Button.button_up.connect(restart)
	update_ui()
	
	if tutorial_step == 0:
		$CanvasLayer/Tutorial/Move.visible = true
		$CanvasLayer/Tutorial/Move.position = Vector2(4, -11)
		$CanvasLayer/Tutorial/Fire.position = Vector2(-5000, -5000)
		$CanvasLayer/Tutorial/Melee.position = Vector2(-5000, -5000)
	
func anim_finished():
	if animated_sprite_2d.animation == "shoot":
		shoot_anim_done()
	elif animated_sprite_2d.animation == "jam":
		animated_sprite_2d.play("idle")
		can_shoot = true
	
func _input(event: InputEvent) -> void:
	if dead or GameState.hitstun:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		

func _process(delta: float) -> void:
	
	
	if GameState.hitstun:
		malfunction_overlay.visible = false
		if GameState.hitstun_remaining > 0.2:
			hitstun_overlay.visible = true
		return
	else:
		malfunction_overlay.visible = GameState.malfunction
		hitstun_overlay.visible = false
		
	weapon_anim.advance(delta)
	
	invulnerable = false
	if post_hit_invulnerable > 0:
		invulnerable = true
		post_hit_invulnerable -= delta
	if melee_invulnerable > 0:
		invulnerable = true
		melee_invulnerable -= delta
	if GameState.malfunction:
		invulnerable = true
		
	process_inputs(delta)
	
	
	bob_speed = lerp(bob_speed, velocity.length(), delta*10)
	bob_t += bob_speed * delta
	camera_3d.position.y = sin(bob_t * BOB_FREQ) * BOB_MAGNITUDE

func process_inputs(_delta):
	if dead: return
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	if Input.is_key_pressed(KEY_F11):
		get_window().mode = Window.MODE_FULLSCREEN
	if Input.is_action_just_pressed("shoot") or (GameState.malfunction and not Input.is_action_pressed("shoot")):
		shoot()
	if Input.is_action_just_pressed("melee"):
		melee()
	

func _physics_process(delta: float) -> void:
	if GameState.hitstun:
		return
	if dead:
		return
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if not direction.is_zero_approx() and tutorial_step == 0:
		tutorial_step += 1
		$CanvasLayer/Tutorial/Fire.visible = true
		tutorial_anim.play("move")
		
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	velocity.y -= 9.8 * delta
	move_and_slide()

func shoot():
	if dead: return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if !can_shoot:
		return
	can_shoot = false
	
	if tutorial_step == 1:
		tutorial_step += 1
		tutorial_anim.play("shoot")
		$CanvasLayer/Tutorial/Move.visible = false
	
	if !GameState.malfunction:	
		if jam_next_shot:
			gun_jammed = true
			jam_next_shot = false
			if tutorial_step == 2:
				tutorial_step += 1
				$CanvasLayer/Tutorial/Melee.visible = true
				tutorial_anim.play("meleestart")
			update_ui()
			
		if gun_jammed or ammo <= 0:
			jammed_sound.play()
			animated_sprite_2d.play("jam")
			return
		
		ammo -= 1
		shots_until_jam -= 1
		if shots_until_jam <= 0:
			jam_next_shot = true
			shots_until_jam = 4
	
	update_ui()
	animated_sprite_2d.play("shoot")
	shoot_sound.play()
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("onhit"):
		ray_cast_3d.get_collider().call("onhit")
		GameState.begin_hitstun(0.05)

func melee():
	if dead: 
		return
	if can_shoot == false or weapon_anim.is_playing():
		return
	can_shoot = false
	weapon_anim.play("melee")
	melee_invulnerable = MELEE_INVULN
	
	

func update_ui():
	$CanvasLayer/Health/HealthCount.text = str(health)
	ammo_count.text = str(ammo)
	ammo_count.add_theme_color_override("font_color", Color("ee0817") if not gun_jammed and ammo > 0 else Color("8a8a8a"))
	GameState.health_drop_chance = calculate_health_percent()

func shoot_anim_done():
	can_shoot = true
	
func restart():
	get_tree().reload_current_scene()

func punch_active():
	var bodies = $PunchArea.get_overlapping_areas() + $PunchArea.get_overlapping_bodies()
	var enemies_hit := 0
	for body in bodies:
		if enemies_hit >= 4:
			continue
		if body == self: continue
		if body.has_method("onhit"):
			body.call("onhit")
			enemies_hit += 1
		if body.has_method("onpunch"):
			body.call("onpunch")
			
	if enemies_hit > 0:
		$MeleeHit.play()
		jam_next_shot = false
		shots_until_jam = 4
		if gun_jammed:
			gun_jammed = false
			play_reload_sound = true
		GameState.begin_hitstun(0.1 + 0.05 * enemies_hit)
		if tutorial_step == 3:
			tutorial_step += 1
			tutorial_anim.play("meleeend")
		
	update_ui()

func reload_sound():
	can_shoot = true
	if play_reload_sound:
		$Unjam.play()
		play_reload_sound = false
	

func onhit():
	if invulnerable:
		return
	
	$CanvasLayer/Fullscreen/ScreenAnim.play("hurt")
	$Hurt.play()
	
	health -= 15
	post_hit_invulnerable = HIT_INVULN
	update_ui()
	if health <= 0:
		GameState.game_over()
		dead = true
		health = 0
		$CanvasLayer/DeathScreen.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_game_ended(_won):
	$CanvasLayer/DeathScreen.show()
	
func add_ammo():
	if ammo < 12:
		ammo+=1
		update_ui()

func add_health():
	health += 10
	health = min(health, max_health)
	update_ui()
	
func calculate_health_percent():
	if health >= 100:
		return 0
	if ammo <= 3:
		return 0
	
	var mod_health = health / 10
	return clamp(float(ammo) / float(mod_health), 0.2, 0.8)
	


func _on_random_stats_timeout() -> void:
	if GameState.malfunction:
		$CanvasLayer/GunBase/AmmoCount.text = str(randi()%100)
		$CanvasLayer/Health/HealthCount.text = str(randi()%1000)
