extends Timer

func despawn(time):
	start(time)
	timeout.connect(get_parent().queue_free)
