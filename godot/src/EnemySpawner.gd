extends Node3D

@onready var negative_bound: Node3D = $"../NegativeBound"
@onready var postive_bound: Node3D = $"../PostiveBound"
@onready var spawn_sound: AudioStreamPlayer3D = $"../EnemySpawner/SpawnSound"
@onready var player: CharacterBody3D = $"../Player"


const ENEMY = preload("res://src/enemy.tscn")
const BARREL = preload("res://src/barrel.tscn")

var wave_size = 5
var wave_number := 1

func get_random_points():
	var x = randf_range(negative_bound.global_position.x, postive_bound.global_position.x)
	var z = randf_range(negative_bound.global_position.z, postive_bound.global_position.z)
	return Vector3(x, 0, z)
	
func pick_random_point():
	var space = get_world_3d().direct_space_state
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 2.0
	var result = [null]
	var current_point := Vector3.ZERO

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.collision_mask = 1
	current_point = get_random_points()
	var valid = false
	while !valid:
		valid = true
		current_point = get_random_points()
		if current_point.distance_to(player.global_position) < 6.0: 
			valid = false
			continue
			
		
		
		var downquery = PhysicsRayQueryParameters3D.create(current_point + Vector3.UP * 100, current_point + Vector3.DOWN * 100)
		query.collision_mask = 1
		result = space.intersect_ray(downquery)
		if result.is_empty():
			valid = false
			continue
		
		current_point = result["position"]
		
		if current_point.y > 3.0:
			valid = false
			continue
		
		query.transform = Transform3D(Basis(), current_point+Vector3.UP * 2.2)
		result = space.intersect_shape(query, 1)
		if result.size() > 0: 
			valid = false
			continue
		
		
	return current_point

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debugnext") and Settings.debug:
		prepare_for_next_wave()

func _ready():
	GameState.wave_cleared.connect(prepare_for_next_wave)

func prepare_for_next_wave():
	wave_number += 1
	wave_size = wave_number+4
	$TimeToWave.start(2.0)
	$WaveSound.play()

func spawn_wave():
	print(wave_number)
	# calculate wave score
	var points = wave_number * (wave_number+1) / 2
	points += 5
	
	var hitscan_count = 0
	var melee_count = 0
	var imp_count = 0
	var spectre_count = 0
	
	if wave_number > GameState.TOTAL_WAVES:
		melee_count = 5
	elif wave_number < 2:
		melee_count = points
	elif wave_number == 2:
		imp_count = ceil(points / 2)
	elif wave_number == 3:
		hitscan_count = ceil(points / 3)
	else:
		if wave_number == 8 or wave_number == 10 or wave_number == 11:
			spectre_count = 1
			points -= 5
		elif wave_number == 13:
			spectre_count = 2
			points -= 5
			
		while points > 3:
			match (randi()%3):
				0:
					melee_count += 1
					points -= 1
				1:
					imp_count += 1
					points -= 2
				2:
					hitscan_count += 1
					points -= 3
	
		melee_count += points
		
	spawn_type(0, melee_count)
	spawn_type(1, imp_count)
	spawn_type(2, hitscan_count)
	spawn_type(3, spectre_count)
	GameState.enemy_count = melee_count + imp_count + hitscan_count + spectre_count
	GameState.count_spectres()
	GameState.wave = wave_number
	
func spawn_barrels():
	var barrel_count = get_tree().get_nodes_in_group("Barrel").size()
	var barrels_to_spawn = 6-barrel_count
	if barrels_to_spawn < 0: barrels_to_spawn = 0
	
	for i in range(barrels_to_spawn):
		var spawn_point = pick_random_point()
		var barrel = BARREL.instantiate()
		get_parent().add_child(barrel)
		barrel.global_position = spawn_point
		spawn_sound.play()

func spawn_type(enemy_type, count):
	for i in range(count):
		var spawn_point = pick_random_point()
		var enemy = ENEMY.instantiate()
		get_parent().add_child(enemy)
		enemy.set_type(enemy_type)
		enemy.global_position = spawn_point + Vector3.UP * 0.2
		spawn_sound.play()
		await get_tree().create_timer(0.2).timeout


func _on_time_to_wave_timeout() -> void:
	spawn_wave()
	spawn_barrels()
