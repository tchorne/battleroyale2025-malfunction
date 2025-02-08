extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.begun_malfunction.connect(_on_malfunction)
	GameState.end_malfunction.connect(_on_malfunction_end)

func _on_malfunction(_first):
	environment.background_mode = Environment.BG_KEEP

func _on_malfunction_end():
	environment.background_mode = Environment.BG_COLOR
