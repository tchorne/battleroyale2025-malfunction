extends Node3D

@onready var negative_bound: Node3D = $"../NegativeBound"
@onready var postive_bound: Node3D = $"../PostiveBound"
const ENEMY = preload("res://src/enemy.tscn")
@onready var spawn_sound: AudioStreamPlayer3D = $"../EnemySpawner/SpawnSound"
@onready var player: CharacterBody3D = $"../Player"

var wave_size = 5

func get_random_points():
	var x = randf_range(negative_bound.global_position.x, postive_bound.global_position.x)
	var y = randf_range(negative_bound.global_position.y, postive_bound.global_position.y)
	return Vector3(x, 0, y)
	
func pick_random_point():
	var space = get_world_3d().direct_space_state
	var sphere_shape = SphereShape3D.new()
	var radius = 1000.0
	var result = [null]
	var current_point := Vector3.ZERO

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.collision_mask = 1+4
	current_point = get_random_points()
	while result.size() > 0 || current_point.distance_to(player.global_position) < 4.0:
		current_point = get_random_points()
		query.transform = Transform3D(Basis(), current_point)
		result = space.intersect_shape(query, 1)
		
	return current_point



func _ready():
	GameState.wave_cleared.connect($TimeToWave.start.bind(2.0))
	
func spawn_wave():
	GameState.enemy_count = wave_size
	for i in range(wave_size):
		var spawn_point = pick_random_point()
		var enemy = ENEMY.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = spawn_point
		spawn_sound.play()
		await get_tree().create_timer(0.2).timeout
	
	
func _on_time_to_wave_timeout() -> void:
	spawn_wave()
