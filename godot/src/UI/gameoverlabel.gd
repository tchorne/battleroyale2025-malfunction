extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.game_ended.connect(update)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update(won):
	if won:
		text = """[font_size=42][center]Victory!
[font_size=26]WAVES BEATEN: {0}
Thank you for playing!
""".format([str(GameState.TOTAL_WAVES)])
	else:
		text = """[font_size=42][center]GAME OVER!
[font_size=26]WAVE REACHED: {0}
You can do better.
""".format([str(GameState.wave)])
