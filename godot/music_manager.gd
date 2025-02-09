extends Node

@onready var full: AudioStreamPlayer = $full
@onready var calm: AudioStreamPlayer = $calm
@onready var nodrums: AudioStreamPlayer = $nodrums

var full_volume := 0.0
var calm_volume := 0.0
var nodrums_volume := 1.0

@onready var current_stream = nodrums
const CROSS_SPEED := 0.5

func _ready():
	_on_full_finished()

func _on_full_finished() -> void:
	full.play(0.0)
	calm.play(0.0)
	nodrums.play(0.0)
	
func fade_to(new):
	current_stream = new

func _process(delta: float) -> void:
	full_volume = clampf(full_volume + delta * (CROSS_SPEED * (1 if current_stream == full else -1)), 0.0, 1.0)
	calm_volume = clampf(calm_volume + delta * (CROSS_SPEED * (1 if current_stream == calm else -1)), 0.0, 1.0)
	nodrums_volume = clampf(nodrums_volume + delta * (CROSS_SPEED * (1 if current_stream == nodrums else -1)), 0.0, 1.0)

	full.volume_db = linear_to_db(full_volume)
	calm.volume_db = linear_to_db(calm_volume)
	nodrums.volume_db = linear_to_db(nodrums_volume)
	
	if Input.is_key_pressed(KEY_2): fade_to(full)
	if Input.is_key_pressed(KEY_3): fade_to(calm)
	if Input.is_key_pressed(KEY_4): fade_to(nodrums)
	
	
