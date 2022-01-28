extends Node

onready var animation_player = $AnimationPlayer
onready var sound_manager = $SoundManager
onready var spawn_timer = $SpawnTimer
onready var screen_manager = $Screens
onready var hud = $HUD

var thing = preload("res://Scenes/SpawnObject.tscn")
var combo = preload("res://Scenes/Combo.tscn")
var arrow_cursor = preload("res://Assets/Menu Icons/upLeft.png")
var x_cursor = preload("res://Assets/Menu Icons/Cursor.png")

var version = "1.0.0"
var highscores = {}

export var circle_radius = 100
var score = 0
var current_highscore
var initial_highscore

var current_level = 1
var current_state
var next_level_threshold = 1000
var next_level = 1000

var polygon_chance = 0
var mobile_chance = 0
var double_chance = 0
var combo_counter = 0
var fail_ratio = 0.0
var difficulty_factor = 2
var paused = false
var last_rainbow_circle_time

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
var INITIAL_DOUBLE_CIRCLE_CHANCE
var DOUBLE_CIRCLE_INCREASE
var MAX_DOUBLE_CIRCLE_CHANCE
var NEXT_LEVEL_INCREASE_FACTOR
var FAIL_CAPACITY
var MINIMAL_RAINBOW_INTERVAL


enum Modes {
	CIRCLE,
	POLYGON,
	RAINBOW_CIRCLE,
	DOUBLE_CIRCLE
}

enum States {
	PLAY,
	PAUSE,
	SCREENS,
	GAME_OVER
}

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.scancode == KEY_ESCAPE:
				get_tree().quit()
			elif event.scancode == KEY_P:
				pause()
				
func _ready():
	Input.set_custom_mouse_cursor(arrow_cursor)
	randomize()
	load_data()
	MIN_X = circle_radius
	MAX_X = int(450- circle_radius)
	MIN_Y = circle_radius + 150
	MAX_Y = int(900 - circle_radius)
	hud.hide()
	current_state = States.SCREENS
	spawn_timer.start()
	sound_manager.play_music(sound_manager.MENU_MUSIC)
	$Screens/TitleScreen/VersionLabel.text = "Version %s" % version

func pause():
	if ![States.PLAY, States.PAUSE].has(current_state):
		return
	
	for obj in get_tree().get_nodes_in_group("SpawnObjects"):
			obj.pause()
	if current_state == States.PLAY:
		current_state = States.PAUSE	
		
	else:
		current_state = States.PLAY
		
	$HUD/PauseLabel.visible = current_state == States.PAUSE	
	spawn_timer.set_paused(current_state == States.PAUSE)


func load_data():
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://highscores.sav", File.READ, "CrazyCircles")
	if !err:
		var data = f.get_var()
		if !data.has("version") or data["version"][0] != version[0]:
			create_data()
		else:
			highscores = data
	else:
		create_data()

	f.close()
	initial_highscore = highscores[difficulty_factor]
	current_highscore = highscores[difficulty_factor]

func create_data():
	highscores = {
			"version": "1.0.0",
			1: 0,
			2: 0,
			3: 0,
		}
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
		if fail_ratio > 0 and OS.get_unix_time() - last_rainbow_circle_time > MINIMAL_RAINBOW_INTERVAL:
			dice_roll = randf()
			if dice_roll < 0.02:
				mode = Modes.RAINBOW_CIRCLE
				last_rainbow_circle_time = OS.get_unix_time()
			else:
				dice_roll = randf()
				if dice_roll < double_chance:
					mode = Modes.DOUBLE_CIRCLE
				else:
					mode = Modes.CIRCLE
		else:
			dice_roll = randf()
			if dice_roll < double_chance:
				mode = Modes.DOUBLE_CIRCLE
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

func spawn_hit_message(obj, count):
	if obj.mode == Modes.CIRCLE and count <= 1:
		return
	var c = combo.instance()
	c.init(count, obj)
	$World.call_deferred("add_child", c)

func game_over():
	current_state = States.GAME_OVER
	highscores[difficulty_factor] = current_highscore
	sound_manager.stop_music()
	sound_manager.play_effect(sound_manager.GAME_OVER)
	spawn_timer.stop()
	for obj in $World.get_children():
		if obj.has_node("AnimationPlayer"):
			obj.get_node("AnimationPlayer").stop()
	save_data()
	screen_manager.next_screen = screen_manager.game_over_screen
	screen_manager.switch_screen()
	
func reset():
	for obj in $World.get_children():
		obj.queue_free()
	fail_ratio = 0
	score = 0
	combo_counter = 0
	current_level = 1
	next_level = 1000


func increase_level():
	current_level += 1
	next_level_threshold *= NEXT_LEVEL_INCREASE_FACTOR
	next_level = score + next_level_threshold
	
	spawn_timer.wait_time = clamp(spawn_timer.wait_time - INTERVAL_DECREASE_RATIO, MIN_INTERVAL, STARTING_INTERVAL)
	polygon_chance = clamp(polygon_chance + POLYGON_CHANCE_INCREASE, INITIAL_POLYGON_CHANCE, MAX_POLYGON_CHANCE)
	mobile_chance = clamp(mobile_chance + MOBILE_CHANCE_INCREASE, INITIAL_MOBILE_CHANCE, MAX_MOBILE_CHANCE)
	
	if current_level >= 6 - difficulty_factor:
		double_chance = clamp(double_chance + DOUBLE_CIRCLE_INCREASE, INITIAL_DOUBLE_CIRCLE_CHANCE, MAX_DOUBLE_CIRCLE_CHANCE)
	
	hud.advance_level(current_level)
	spawn_timer.stop()

func update_hud():
	hud.update_labels(hud.score_label, score)
	hud.update_labels(hud.combo_label, combo_counter)
	hud.update_labels(hud.highscore_label, current_highscore)
	hud.update_bars(hud.fail_label, fail_ratio, FAIL_CAPACITY)

func set_gameplay_values():
	match difficulty_factor:
		1:
			STARTING_INTERVAL = 1.8
			MIN_INTERVAL = 0.5
			INTERVAL_DECREASE_RATIO = 0.15
			INITIAL_MOBILE_CHANCE = 0
			MOBILE_CHANCE_INCREASE = 0.05
			MAX_MOBILE_CHANCE = 0.5
			INITIAL_POLYGON_CHANCE = 0.05
			POLYGON_CHANCE_INCREASE = 0.025 
			MAX_POLYGON_CHANCE = 0.2
			NEXT_LEVEL_INCREASE_FACTOR = 1.2
			FAIL_CAPACITY = 100
			INITIAL_DOUBLE_CIRCLE_CHANCE = 0
			DOUBLE_CIRCLE_INCREASE = 0.015
			MAX_DOUBLE_CIRCLE_CHANCE = 0.1
			MINIMAL_RAINBOW_INTERVAL = 20
			
		2:
			STARTING_INTERVAL = 1.75
			MIN_INTERVAL = 0.35
			INTERVAL_DECREASE_RATIO = 0.175
			INITIAL_MOBILE_CHANCE = 0.1
			MOBILE_CHANCE_INCREASE = 0.075
			MAX_MOBILE_CHANCE = 0.65
			INITIAL_POLYGON_CHANCE = 0.1
			POLYGON_CHANCE_INCREASE = 0.05 
			MAX_POLYGON_CHANCE = 0.25
			NEXT_LEVEL_INCREASE_FACTOR = 1.25
			FAIL_CAPACITY = 90
			INITIAL_DOUBLE_CIRCLE_CHANCE = 0
			DOUBLE_CIRCLE_INCREASE = 0.02
			MAX_DOUBLE_CIRCLE_CHANCE = 0.125
			MINIMAL_RAINBOW_INTERVAL = 30
			
		3:
			STARTING_INTERVAL = 1.7
			MIN_INTERVAL = 0.25
			INTERVAL_DECREASE_RATIO = 0.2
			INITIAL_MOBILE_CHANCE = 0.2
			MOBILE_CHANCE_INCREASE = 0.1
			MAX_MOBILE_CHANCE = 0.7
			INITIAL_POLYGON_CHANCE = 0.15
			POLYGON_CHANCE_INCREASE = 0.075 
			MAX_POLYGON_CHANCE = 0.3
			NEXT_LEVEL_INCREASE_FACTOR = 1.3
			FAIL_CAPACITY = 80
			INITIAL_DOUBLE_CIRCLE_CHANCE = 0
			DOUBLE_CIRCLE_INCREASE = 0.025
			MAX_DOUBLE_CIRCLE_CHANCE = 0.15
			MINIMAL_RAINBOW_INTERVAL = 40
	
	mobile_chance = INITIAL_MOBILE_CHANCE
	polygon_chance = INITIAL_POLYGON_CHANCE
	double_chance = INITIAL_DOUBLE_CIRCLE_CHANCE		
	$HUD/ProgressBars/VBoxContainer2/HBoxContainer/FailProgress.max_value = FAIL_CAPACITY

func _on_SpawnObject_inner_popped(_obj):
	sound_manager.play_effect(sound_manager.CIRCLE_HIT)

func _on_SpawnObject_popped(obj):
	if current_state != States.PLAY:
		return
		
	var combo_threshold = 0.65 if obj.initial_mode == Modes.DOUBLE_CIRCLE else 0.8
	if obj.mode != Modes.POLYGON:
		if obj.mode == Modes.RAINBOW_CIRCLE:
			fail_ratio = clamp(fail_ratio - 15.0, 0.0, 100.0)
			animation_player.queue("Heal")
		if obj.scale.x >= combo_threshold:
			combo_counter += 1
		else:
			combo_counter = 0
		
		score += floor(obj.scale.x * obj.value * (1 + 0.075 * combo_counter))
		if score > current_highscore:
			current_highscore = score
		
		if score >= next_level:
			increase_level()

		if obj.mode == Modes.RAINBOW_CIRCLE:
			sound_manager.play_effect(sound_manager.HEAL)
		else:	
			sound_manager.play_effect(sound_manager.CIRCLE_HIT, 1.0 + 0.015 * combo_counter)
	else:
		combo_counter = 0
		if current_highscore > initial_highscore and current_highscore == score:
			current_highscore = clamp(current_highscore - 250, initial_highscore, current_highscore)	
		score = clamp(score - 250, 0, INF)
		fail_ratio += 15.0
		animation_player.queue("Hurt")
		sound_manager.play_effect(sound_manager.POLYGON_HIT, rand_range(0.8, 1.0))
	
	spawn_hit_message(obj, combo_counter)
	update_hud()	

	if fail_ratio >= FAIL_CAPACITY:
		game_over()
		

func _on_SpawnObject_perished(obj):
	if current_state == States.PLAY and obj.mode != Modes.POLYGON:
		if current_highscore > initial_highscore and current_highscore == score:
			current_highscore = clamp(current_highscore - 50, 0, INF)	
		score = clamp(score - 50, 0, INF)
		combo_counter = 0
		fail_ratio += 5.0
		update_hud()
		sound_manager.play_effect(sound_manager.POLYGON_HIT, rand_range(0.8, 1.0))
		animation_player.queue("Hurt")
		if fail_ratio >= FAIL_CAPACITY:
			game_over()
	
func _on_Timer_timeout():
	if $World.get_child_count() < 6:
		spawn()


func _Start_game():
	reset()
	set_gameplay_values()
	update_hud()
	spawn_timer.stop()
	current_state = States.PLAY
	for obj in $World.get_children():
		obj.queue_free()
	yield(get_tree().create_timer(0.5), "timeout")
	spawn_timer.wait_time = STARTING_INTERVAL
	hud.show_phrase()
	sound_manager.stop_music()


func _on_Level_advanced():
	spawn_timer.start()

func _on_HUD_phrase_shown():
	yield(get_tree().create_timer(0.5), "timeout")
	hud.show()
	Input.set_custom_mouse_cursor(x_cursor, 0, Vector2(16, 16))
	yield(get_tree().create_timer(0.75), "timeout")
	hud.advance_level(current_level)
	spawn_timer.start()
	sound_manager.play_music(sound_manager.GAME_MUSIC_1 + randi() % 2)
	last_rainbow_circle_time = OS.get_unix_time()

func _on_Screens_title_screen():
	hud.hide()
	for obj in $World.get_children():
		obj.queue_free()


func _on_Screens_restart():
	hud.hide()
	sound_manager.stop_effects()
	_Start_game()
	

func _on_DifficultySlider_value_changed(value):
	difficulty_factor = int(value)
	current_highscore = highscores[difficulty_factor]
	initial_highscore = highscores[difficulty_factor]

func _on_PauseButton_pressed():
	pause()
