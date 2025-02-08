extends Timer

var started := false

func despawn(time):
	if started: return
	started = true
	start(time)
	timeout.connect(get_parent().queue_free)
