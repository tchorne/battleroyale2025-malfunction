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
	query.collision_mask = 1+4
	current_point = get_random_points()
	while result.size() > 0 || current_point.distance_to(player.global_position) < 4.0:
		current_point = get_random_points()
		query.transform = Transform3D(Basis(), current_point+Vector3.UP * 2.2)
		result = space.intersect_shape(query, 1)
		
	return current_point



func _ready():
	GameState.wave_cleared.connect(prepare_for_next_wave)

func prepare_for_next_wave():
	wave_number += 1
	wave_size = wave_number+4
	$TimeToWave.start(2.0)

func spawn_wave():
	GameState.enemy_count = wave_size
	for i in range(wave_size):
		var spawn_point = pick_random_point()
		var enemy = ENEMY.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = spawn_point
		spawn_sound.play()
		await get_tree().create_timer(0.2).timeout

func spawn_barrels():
	var barrel_count = get_tree().get_nodes_in_group("Barrel").size()
	var barrels_to_spawn = 4-barrel_count
	
	for i in range(wave_size):
		var spawn_point = pick_random_point()
		var barrel = BARREL.instantiate()
		get_parent().add_child(barrel)
		barrel.global_position = spawn_point
		spawn_sound.play()

func _on_time_to_wave_timeout() -> void:
	spawn_wave()
	spawn_barrels()
