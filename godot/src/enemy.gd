extends CharacterBody3D

signal died(spectre: bool)

const BULLET_DROP = preload("res://src/bullet_drop.tscn")
const FIREBALL = preload("res://src/fireball.tscn")
const FIREBALL_SPEED = 4.5
const TYPE_MELEE = 0
const TYPE_RANGED = 1
const TYPE_HITSCAN = 2
const TYPE_SPECTRE = 3

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var pausable_timers: Node = $PausableTimers
@onready var attack_timer: Timer = $PausableTimers/AttackTimer
@export var move_speed := 2.7
@export var attack_range := 1.5
@onready var hitbox: CollisionShape3D = $Hitbox/Hitbox

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("Player")

var dead = false

var end_ammo_drop := 0
var played_sound := false

var type = TYPE_HITSCAN
var hitscan_player_position := Vector3.ZERO
var health = 1

func _ready():
	$SpawnParticles.restart()
	died.connect(GameState.enemy_killed)
	GameState.end_malfunction.connect(_on_malfunction_end)
	animated_sprite_3d.animation_finished.connect(anim_done)
	idle_anim()

func set_type(newtype):
	type = newtype
	if type == TYPE_SPECTRE: 
		health=6 
		animated_sprite_3d.position.y +=1
	idle_anim()
	if type == TYPE_RANGED or type == TYPE_HITSCAN:
		$UpdateNavigation.start(1.2)
		
func anim_done():
	if !dead:
		idle_anim()

func idle_anim():
	match type:
		TYPE_MELEE:
			animated_sprite_3d.play("idle")
		TYPE_RANGED:
			animated_sprite_3d.play("impidle")
		TYPE_HITSCAN:
			animated_sprite_3d.play("shotgunidle")
		TYPE_SPECTRE:
			animated_sprite_3d.play("spectreidle")
			
func attack_anim():
	match type:
		TYPE_RANGED:
			animated_sprite_3d.play("impfireball")
		TYPE_HITSCAN:
			animated_sprite_3d.play("shotgunattack")

func _on_malfunction_end():
	if dead and !played_sound:
		played_sound = true
		$DeathSound.play()
	for i in range(end_ammo_drop):
		spawn_ammo()
	end_ammo_drop = 0
	
func _process(_delta: float) -> void:
	if dead and GameState.malfunction:
		animated_sprite_3d.modulate.a = 0.2
	else:
		if type == TYPE_SPECTRE and !GameState.malfunction and not dead:
			animated_sprite_3d.modulate.a = 0.4
		else:
			animated_sprite_3d.modulate.a = 1.0
			
	animated_sprite_3d.speed_scale = 0 if GameState.hitstun or (GameState.malfunction and type != TYPE_SPECTRE) else 1
	pausable_timers.process_mode = Node.PROCESS_MODE_DISABLED if GameState.hitstun or GameState.malfunction else PROCESS_MODE_INHERIT
	
func _physics_process(delta: float) -> void:
	if type == TYPE_SPECTRE:
		hitbox.disabled = not GameState.malfunction
	if GameState.hitstun or (GameState.malfunction and type != TYPE_SPECTRE):
		return
	if dead:
		return
	if player == null:
		return
	
	# This section is from tutorial but direct towards player movement has been replaced with pathfinding
	var next_point = navigation_agent_3d.get_next_path_position()
	var dir = navigation_agent_3d.get_next_path_position() - global_position
	dir.y = 0.0
	dir = dir.normalized()
	
	velocity.x = (dir * get_speed()).x
	velocity.z = (dir * get_speed()).z
	velocity.y -= 9.8* delta
	move_and_slide()
	# --------------------------------------------------------------------------
	
	#global_position.y = 0
	
	attempt_to_kill_player()

func get_speed():
	match (type):
		TYPE_MELEE:
			return move_speed
		TYPE_RANGED: 
			return move_speed*0.75
		TYPE_HITSCAN: 
			return move_speed*0.8
		TYPE_SPECTRE: 
			return move_speed*1.1

func onhit():
	if dead: return
	health -= 1
	if health <= 0:
		die()
	else:
		animated_sprite_3d.play("hurt")

func die():
	died.emit(type == TYPE_SPECTRE)
	if GameState.malfunction:
		end_ammo_drop = ceil(GameState.malfunction_combo / 2)
	else:
		played_sound = true
		if type==TYPE_SPECTRE:
			$DeathSound.pitch_scale = 0.7
		$DeathSound.play()
		
	dead = true
	if type == TYPE_SPECTRE:
		animated_sprite_3d.position.y -= 0.5
		animated_sprite_3d.play("spectredeath")
	else:
		animated_sprite_3d.play("death")
	$CollisionShape3D.disabled = true
	$Hitbox/Hitbox.disabled = true
	$Despawner.despawn(15.0)

func onpunch():
	for i in range(2):
		spawn_ammo()
		
func spawn_ammo():
	var drop = BULLET_DROP.instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector3.UP * 1.3
	
func update_navigation():
	navigation_agent_3d.target_position = player.global_position
	match(type):
		TYPE_RANGED:
			if global_position.distance_squared_to(player.global_position) < 80:
				pathfind_away(randf_range(10.0, 15.0))
		TYPE_HITSCAN:
			if global_position.distance_squared_to(player.global_position) < 30:
				pathfind_away(randf_range(5.0, 10.0))

func pathfind_away(dist):
	var from_player = global_position - player.global_position
	from_player = from_player.rotated(Vector3.UP, randf_range(-PI/4, PI/4))
	from_player = from_player.normalized() * dist
	navigation_agent_3d.target_position = from_player

func attempt_to_kill_player():
	if type != TYPE_MELEE and type != TYPE_SPECTRE: return
	# From doom tutorial ----------------------------------------
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
	
	var eye_line = Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		player.onhit()
	# -----------------------------------------------------------
		
	


func _on_attack_timer_timeout() -> void:
	if dead: return
	match(type):
		TYPE_MELEE:
			pass
		TYPE_RANGED:
			if player_in_distance(8, 25) and has_los():
				stop_and_fire()
				attack_anim()
			else:
				attack_timer.start(1.0)
		TYPE_HITSCAN:
			if player_in_distance(3, 15) and has_los():
				stop_and_fire()
				$Shotgun.play()
				attack_anim()
			else:
				attack_timer.start(0.5)
		TYPE_SPECTRE:
			pass

func stop_and_fire():
	var stop_timer: Timer = $PausableTimers/StopTimer
	match(type):
		TYPE_RANGED:
			stop_timer.start(0.5)
		TYPE_HITSCAN:
			stop_timer.start(0.7)
	hitscan_player_position = player.global_position
	
func fire():
	if dead: return
	match(type):
		TYPE_RANGED:
			# Throw a projectile
			var fireball = FIREBALL.instantiate()
			get_parent().add_child(fireball)
			fireball.global_position = global_position + Vector3.UP * 1.3
			fireball.velocity = (player.global_position + Vector3.UP * 1.3 - fireball.global_position).normalized() * FIREBALL_SPEED
			
			attack_timer.start(randf_range(4.0, 6.0))
			
		TYPE_HITSCAN:
			$Shotgun2.play()
			var to_bullet := hitscan_player_position - global_position
			var to_player := player.global_position - global_position
			var perp = to_player - ((to_player.dot(to_bullet) / to_bullet.length_squared()) * to_bullet)
			if perp.length() < 1 and to_player.angle_to(to_bullet) < PI/3:
				player.onhit()
				
			attack_timer.start(randf_range(4.0, 6.0))
			
func _on_stop_timer_timeout() -> void:
	fire()
	
func has_los():
	if type == TYPE_HITSCAN and abs((global_position - player.global_position).y) > 1.0: return false
	if type == TYPE_HITSCAN and global_position.distance_squared_to(player.global_position) > 400: return false
	
	var query = PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.5, player.global_position + Vector3.UP * 1.5)
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	
func player_in_distance(a, b):
	if global_position.distance_squared_to(player.global_position) > b * b: return false
	if global_position.distance_squared_to(player.global_position) < a * a: return false
	
	return true
	
