extends SubViewport

func _ready():
	size = get_window().size
	get_window().size_changed.connect(update_size)

func update_size():
	size = get_window().size
	
