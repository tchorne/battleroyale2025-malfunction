@tool
class_name settingSensitivity
extends ggsSetting

func _init():
	value_type = TYPE_INT
	value_hint = PROPERTY_HINT_RANGE

func apply(sens: int):
	Settings.sensitivity = float(sens)/100.0
