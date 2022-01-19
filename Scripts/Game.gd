extends Node

var thing = preload("res://Scenes/SpawnObject.tscn")
var explosion = preload("res://Scenes/Explosion.tscn")
var combo = preload("res://Scenes/Combo.tscn")

export var circle_radius = 100
var score = 0
var highscores = {
	1: 0,
	2: 0,
	3: 0,
}
var current_highscore
var initial_highscore
var current_level = 1
var current_state
var next_level = 1000
var polygon_chance = 0.1
var mobile_chance = 0.1
var combo_counter = 0
var fail_ratio = 0.0
var fail_capacity = 100
var difficulty_factor = 2


var MIN_X
var MAX_X
var MIN_Y
var MAX_Y
var STARTING_INTERVAL
var MIN_INTERVAL
var INTERVAL_DECREASE_RATIO
var INITIAL_POLYGON_CHANCE
var POLYGON_CHANCE_INCREASE
var MAX_POLYGON_CHANCE
var INITIAL_MOBILE_CHANCE
var MOBILE_CHANCE_INCREASE
var MAX_MOBILE_CHANCE
var NEXT_LEVEL_INCREASE_FACTOR



enum Modes {
	CIRCLE,
	POLYGON,
	RAINBOW_CIRCLE
}

enum States {
	PLAY,
	SCREENS,
	GAME_OVER
}

func _input(event):
	if event is InputEventKey:
		if event.is_pressed() and event.scancode == KEY_ESCAPE:
			get_tree().quit()
	
	
func _ready():
	randomize()
	load_data()
	MIN_X = circle_radius
	MAX_X = int(450- circle_radius)
	MIN_Y = circle_radius + 150
	MAX_Y = int(900 - circle_radius)
	$HUD.hide()
	current_state = States.SCREENS
	$Timer.start()
	$SoundManager.play_music($SoundManager.MENU_MUSIC)

func load_data():
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://highscores.sav", File.READ, "CrazyCircles")
	if !err:
		highscores = f.get_var()
	else:
		highscores = {
			1: 0,
			2: 0,
			3: 0,
		}
		print("Error: %s" % err)
	f.close()
	initial_highscore = highscores[difficulty_factor]
	current_highscore = highscores[difficulty_factor]
	
func save_data():
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://highscores.sav", File.WRITE, "CrazyCircles")
	if !err:
		f.store_var(highscores)
	f.close()

func spawn():
	var dice_roll = randf()
	var mobile = false
	var mode
	var spawn_object = thing.instance()
	var disable = false
	if dice_roll > polygon_chance:
		if fail_ratio > 0:
			dice_roll = randf()
			if dice_roll < 0.02:
				mode = Modes.RAINBOW_CIRCLE
			else:
				mode = Modes.CIRCLE
		else:
			mode = Modes.CIRCLE
	else:
		mode = Modes.POLYGON
	dice_roll = randf()
	if dice_roll < mobile_chance:
		mobile = true
	if current_state == States.SCREENS:
		disable = true
	spawn_object.position = Vector2(MIN_X + randi() % (MAX_X - MIN_X), MIN_Y + randi() % (MAX_Y - MIN_Y))
	spawn_object.init(mode, mobile, current_level, disable, difficulty_factor)
	$World.add_child(spawn_object)
	if mode == Modes.POLYGON:
		$World.move_child(spawn_object, 0)


func spawn_explosion(obj):
	var e = explosion.instance()
	e.position = obj.position
	$World.add_child(e)
	e.init(obj.mode, obj.color, obj.points.size())

func spawn_combo(obj, count):
	var c = combo.instance()
	c.position = obj.position
	c.init(count, obj.color)
	$World.call_deferred("add_child", c)

func game_over():
	current_state = States.GAME_OVER
	highscores[difficulty_factor] = current_highscore
	$SoundManager.stop_music()
	$SoundManager.play_effect($SoundManager.GAME_OVER)
	$Timer.stop()
	for obj in $World.get_children():
		if obj.has_node("AnimationPlayer"):
			obj.get_node("AnimationPlayer").stop()
	save_data()
	$Screens.next_screen = $Screens.game_over_screen
	$Screens.switch_screen()
	
func reset():
	for obj in $World.get_children():
		obj.queue_free()
	fail_ratio = 0
	score = 0
	combo_counter = 0


func increase_level():
	$Timer.wait_time = clamp($Timer.wait_time - INTERVAL_DECREASE_RATIO, MIN_INTERVAL, STARTING_INTERVAL)
	polygon_chance = clamp(polygon_chance + POLYGON_CHANCE_INCREASE, INITIAL_POLYGON_CHANCE, MAX_POLYGON_CHANCE)
	mobile_chance = clamp(mobile_chance + 0.025 * MOBILE_CHANCE_INCREASE, INITIAL_MOBILE_CHANCE, MAX_MOBILE_CHANCE)
	next_level = score + next_level * NEXT_LEVEL_INCREASE_FACTOR
	current_level += 1
	$HUD.advance_level(current_level)
	$Timer.stop()

func update_hud():
	$HUD.update_labels($HUD.score_label, score)
	$HUD.update_labels($HUD.combo_label, combo_counter)
	$HUD.update_labels($HUD.highscore_label, current_highscore)
	$HUD.update_bars($HUD.fail_label, fail_ratio, fail_capacity)

func set_gameplay_values():
	match difficulty_factor:
		1:
			STARTING_INTERVAL = 2.1
			MIN_INTERVAL = 0.5
			INTERVAL_DECREASE_RATIO = 0.15
			INITIAL_MOBILE_CHANCE = 0
			MOBILE_CHANCE_INCREASE = 0.05
			MAX_MOBILE_CHANCE = 0.5
			INITIAL_POLYGON_CHANCE = 0.05
			POLYGON_CHANCE_INCREASE = 0.025 
			MAX_POLYGON_CHANCE = 0.2
			NEXT_LEVEL_INCREASE_FACTOR = 1.1
			
		2:
			STARTING_INTERVAL = 2.0
			MIN_INTERVAL = 0.35
			INTERVAL_DECREASE_RATIO = 0.2
			INITIAL_MOBILE_CHANCE = 0.1
			MOBILE_CHANCE_INCREASE = 0.075
			MAX_MOBILE_CHANCE = 0.65
			INITIAL_POLYGON_CHANCE = 0.1
			POLYGON_CHANCE_INCREASE = 0.05 
			MAX_POLYGON_CHANCE = 0.25
			NEXT_LEVEL_INCREASE_FACTOR = 1.1
		3:
			STARTING_INTERVAL = 1.8
			MIN_INTERVAL = 0.25
			INTERVAL_DECREASE_RATIO = 0.25
			INITIAL_MOBILE_CHANCE = 0.2
			MOBILE_CHANCE_INCREASE = 0.1
			MAX_MOBILE_CHANCE = 0.7
			INITIAL_POLYGON_CHANCE = 0.15
			POLYGON_CHANCE_INCREASE = 0.075 
			MAX_POLYGON_CHANCE = 0.3
			NEXT_LEVEL_INCREASE_FACTOR = 1.1

func _on_SpawnObject_popped(obj):
	var combo_level = 0
	if current_state == States.PLAY:
		if obj.mode != Modes.POLYGON:
			if obj.mode == Modes.RAINBOW_CIRCLE:
				fail_ratio = clamp(fail_ratio - 10.0, 0.0, 100.0)
			if obj.scale.x >= 0.8:
				combo_counter += 1
				if combo_counter > 1:
					spawn_combo(obj, combo_counter)
				if combo_counter > 5:
					combo_level = 1
				if combo_counter > 10:
					combo_level = 2
			else:
				combo_counter = 0

			score += floor(obj.scale.x * 100 + 10 * combo_counter)
			if score > current_highscore:
				current_highscore = score
			
			if score >= next_level:
				increase_level()

				
			$SoundManager.play_effect($SoundManager.CIRCLE_HIT + combo_level)
		else:
			combo_counter = 0
			if current_highscore > initial_highscore and current_highscore == score:
				current_highscore = clamp(current_highscore - 250, initial_highscore, current_highscore)	
			score = clamp(score - 250, 0, INF)
			fail_ratio += 15.0
			$AnimationPlayer.queue("Hurt")
			$SoundManager.play_effect($SoundManager.POLYGON_HIT + randi() % 3)
		
		update_hud()	
		spawn_explosion(obj)
		if fail_ratio >= fail_capacity:
			game_over()
		

func _on_SpawnObject_perished(obj):
	if current_state == States.PLAY and obj.mode != Modes.POLYGON:
		if current_highscore > initial_highscore and current_highscore == score:
			current_highscore = clamp(current_highscore - 50, 0, INF)	
		score = clamp(score - 50, 0, INF)
		combo_counter = 0
		fail_ratio += 5.0
		update_hud()
		$SoundManager.play_effect($SoundManager.POLYGON_HIT + randi() % 3)
		if fail_ratio >= fail_capacity:
			game_over()
	
func _on_Timer_timeout():
	if $World.get_child_count() < 6:
		spawn()


func _Start_game():
	reset()
	set_gameplay_values()
	update_hud()
	$Timer.stop()
	current_state = States.PLAY
	for obj in $World.get_children():
		obj.queue_free()
	yield(get_tree().create_timer(0.5), "timeout")
	$Timer.wait_time = STARTING_INTERVAL
	$HUD.show_phrase()
	$SoundManager.stop_music()

func _on_Level_advanced():
	$Timer.start()


func _on_HUD_phrase_shown():
	yield(get_tree().create_timer(0.5), "timeout")
	$HUD.show()
	yield(get_tree().create_timer(0.75), "timeout")
	$HUD.advance_level(current_level)
	$Timer.start()
	$SoundManager.play_music($SoundManager.GAME_MUSIC_1 + randi() % 2)


func _on_Screens_title_screen():
	$HUD.hide()
	for obj in $World.get_children():
		obj.queue_free()


func _on_Screens_restart():
	$HUD.hide()
	$SoundManager.stop_effects()
	_Start_game()
	

func _on_DifficultySlider_value_changed(value):
	difficulty_factor = int(value)
	current_highscore = highscores[difficulty_factor]
	initial_highscore = highscores[difficulty_factor]
