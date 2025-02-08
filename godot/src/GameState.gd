extends Node

signal wave_cleared()
signal malfunction_begin()
signal malfunction_end()

var hitstun := false
var malfunction := false

var enemy_count := 0


func enemy_killed():
	enemy_count -= 1
	if enemy_count == 0:
		wave_cleared.emit()
