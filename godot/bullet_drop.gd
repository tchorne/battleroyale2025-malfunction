extends RigidBody3D

const LAUNCH = 2.0
@onready var cpu_particles_3d: CPUParticles3D = $CPUParticles3D

var no_pickup_time = 1.0
var retained_velocity = Vector3.ZERO

var towards_player := false
var player: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	linear_velocity = Vector3(randf()-0.5, 0.3, randf()-0.5).normalized() * LAUNCH
	GameState.begun_hitstun.connect(store_vel)
	
	
func store_vel():
	retained_velocity = linear_velocity
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if GameState.hitstun or GameState.malfunction: freeze = true
	elif freeze:
		freeze = false
		linear_velocity = retained_velocity
		angular_velocity = Vector3(randf(), randf(), randf())
	
	if !freeze and linear_velocity.length() < 0.2:
		cpu_particles_3d.emitting = false
	
	if no_pickup_time > 0 and !freeze:
		no_pickup_time -= delta
		
	if (global_position - player.global_position).length() < 3 and no_pickup_time < 0:
		towards_player = true
		
	if towards_player:
		apply_central_force((player.global_position-linear_velocity*0.5 - global_position).normalized() * 10.0)
		gravity_scale = 0.0
		if (global_position - player.global_position).length() < 0.8:
			player.add_ammo()
			visible = false
			queue_free()
	


func _on_pickup_radius_body_entered(_body: Node3D) -> void:
	towards_player = true
