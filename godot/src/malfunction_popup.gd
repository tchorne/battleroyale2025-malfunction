extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.begun_malfunction.connect(_on_malfunction)
	GameState.end_malfunction.connect(_on_malfunction_end)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var time_progress = (GameState.malfunction_totaltime - GameState.malfunction_remaining) / GameState.malfunction_totaltime
	
	texture_progress_bar.value = lerp(2.0/16.0, 14.0/16.0, time_progress*16)
	
	
func _on_malfunction(first):
	if first:
		animation_player.play("firstmalfunction")
	else:
		animation_player.play("secondmalfunction")
		

func _on_malfunction_end():
	visible = false
