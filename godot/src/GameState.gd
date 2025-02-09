extends Node

signal wave_cleared()
signal begun_malfunction(first: bool)
signal end_malfunction()
signal begun_hitstun()
signal game_ended(won: bool)
signal combo_increased(amount)

const TOTAL_WAVES = 13

const HITSTUN_REQUIREMENT = 1.0

var wave := 0


var hitstun := false
var malfunction := false
var malfunction_totaltime := 1.0

var first_malfunction := true
var health_drops_remaining := 15
var health_drop_chance := 0.0

var enemy_count := 0
var spectre_count := 0

var hitstun_remaining := 0.0
var hitstun_mult = 1.0

var malfunction_remaining := 0.0

var malfunction_combo := 0

var wave_won_this_frame := false

func enemy_killed(spectre):
	enemy_count -= 1
	if spectre:
		spectre_count -= 1
	if enemy_count <= spectre_count:
		if wave_won_this_frame: return
		print("WAVE CLEARED", wave)
		if wave >= TOTAL_WAVES and spectre_count == 0:
			game_ended.emit(true)
		else:
			wave_cleared.emit()
			wave_won_this_frame = true
	if malfunction:
		malfunction_combo += 1
		combo_increased.emit(malfunction_combo)

func _process(delta: float) -> void:
	wave_won_this_frame = false
	if hitstun:
		hitstun_remaining -= delta
		if hitstun_remaining <= 0:
			hitstun = false
			
	if malfunction:
		malfunction_remaining -= delta
		if malfunction_remaining <= 0:
			first_malfunction = false
			malfunction = false
			end_malfunction.emit()
			MusicManager.fade_to(MusicManager.full)
	
	if Input.is_key_pressed(KEY_1) and Settings.debug:
		begin_hitstun(1.0)
	if Input.is_action_just_pressed("debugkill") and Settings.debug:
		for i in get_tree().get_nodes_in_group("Enemy"):
			i.onhit()
	
		
func begin_hitstun(duration, _show_cursor = false):
	if malfunction: return
	
	var new_duration = duration * hitstun_mult
	hitstun_mult += (duration) * (2 if first_malfunction else 1)
	duration = new_duration
	
	if hitstun and duration < hitstun_remaining: return
	hitstun = true

	hitstun_remaining = min(HITSTUN_REQUIREMENT, duration)
	begun_hitstun.emit()
	
	if duration > HITSTUN_REQUIREMENT:
		if first_malfunction: 
			hitstun_remaining *= 5.0
			#duration *= 9.0
			duration = 12.0
		else:
			hitstun_remaining *= 1.5
			duration *= 5.5
			#duration = max(duration, 8.0)
			duration = 6.0
		begun_malfunction.emit(first_malfunction)
		malfunction_totaltime = duration
		malfunction_remaining = malfunction_totaltime
		hitstun_mult = 1.0
		
		malfunction = true
		malfunction_combo = 0
		MusicManager.fade_to(MusicManager.calm)

func game_over():
	game_ended.emit(false)

func count_spectres():
	spectre_count = 0
	for i in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(i) and i.type == 3 and not i.dead:
			spectre_count += 1
		
