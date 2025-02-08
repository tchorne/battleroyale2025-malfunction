extends CharacterBody3D

signal died

const BULLET_DROP = preload("res://src/bullet_drop.tscn")

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

@export var move_speed := 2.0
@export var attack_range := 1.5

@onready var player : CharacterBody3D = get_tree().get_first_node_in_group("Player")
var dead = false

var end_ammo_drop := 0
var played_sound := false

func _ready():
	died.connect(GameState.enemy_killed)
	GameState.end_malfunction.connect(_on_malfunction_end)
	

func _on_malfunction_end():
	if dead and !played_sound:
		played_sound = true
		$DeathSound.play()
	for i in range(end_ammo_drop):
		spawn_ammo()
	end_ammo_drop = 0
	
func _process(_delta: float) -> void:
	animated_sprite_3d.speed_scale = 0 if GameState.hitstun or GameState.malfunction else 1
	
func _physics_process(_delta: float) -> void:
	if GameState.hitstun or GameState.malfunction:
		return
	if dead:
		return
	if player == null:
		return
		
	var dir = player.global_position - global_position
	dir.y = 0.0
	dir = dir.normalized()
	
	velocity = dir * move_speed
	move_and_slide()
	
	global_position.y = 0
	
	attempt_to_kill_player()
	
func onhit():
	die()

func die():
	died.emit()
	if GameState.malfunction:
		end_ammo_drop = ceil(GameState.malfunction_combo / 3)
		print(end_ammo_drop)
	else:
		played_sound = true
		$DeathSound.play()
		
	dead = true
	animated_sprite_3d.play("death")
	$CollisionShape3D.disabled = true

func onpunch():
	for i in range(2):
		spawn_ammo()
		
func spawn_ammo():
	var drop = BULLET_DROP.instantiate()
	get_parent().add_child(drop)
	drop.global_position = global_position + Vector3.UP * 1.3
	

func attempt_to_kill_player():
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > attack_range:
		return
	
	var eye_line = Vector3.UP * 1.5
	var query = PhysicsRayQueryParameters3D.create(global_position+eye_line, player.global_position+eye_line, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		player.onhit()
		
	
