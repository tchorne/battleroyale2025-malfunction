extends RichTextLabel


func _process(_delta: float) -> void:
	text = """        WAVE: {0}
ENEMIES LEFT: {1}
{2}""".format(
	[str(GameState.wave), str(GameState.enemy_count), "[color=yellow][shake=1.5]      COMBO: {0}".format([GameState.malfunction_combo]) if GameState.malfunction and !GameState.first_malfunction else ""]
)
