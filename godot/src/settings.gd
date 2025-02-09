extends Control

var sensitivity := 0.0
var blur := true
var debug := true
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		if get_tree().paused:
			resume()
		else:
			open()

func open():
	canvas_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func resume():
	get_tree().paused = false
	canvas_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
