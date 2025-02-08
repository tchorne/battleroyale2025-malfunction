extends Sprite3D

@onready var ui_position: Node3D = %UIPosition

func _ready():
	GameState.begun_malfunction.connect(capture_ui)

func _process(_delta: float) -> void:
	#if !GameState.malfunction:
		#global_transform = ui_position.global_transform
	pass
	
func capture_ui(_first):
	var image := $"../CanvasLayer".get_viewport().get_texture().get_image()
	texture = ImageTexture.create_from_image(image)
