extends Node

var thing = preload("res://Scenes/SpawnObject.tscn")
var explosion = preload("res://Scenes/Explosion.tscn")
var combo = preload("res://Scenes/Combo.tscn")

export var circle_radius = 100
var score = 0
var current_level = 1
var current_state
var next_level = 1000
var polygon_chance = 0.1
var mobile_chance = 0
var combo_counter = 0
var fail_ratio = 0.0
var fail_capacity = 100

var MIN_X
var MAX_X
var MIN_Y
var MAX_Y

enum Modes {
	CIRCLE,
	POLYGON
}

enum States {
	PLAY,
	SCREENS,
	GAME_OVER
}
func _ready():
	randomize()
	MIN_X = circle_radius
	MAX_X = int(get_viewport().size.x - circle_radius)
	MIN_Y = circle_radius
	MAX_Y = int(get_viewport().size.y - circle_radius)
	$HUD.hide()
	$HUD.update_labels($HUD.score_label, score)
	$HUD.update_labels($HUD.combo_label, score)
	current_state = States.SCREENS
	$Timer.start()

func spawn():
	var dice_roll = randf()
	var mobile = false
	var mode
	var spawn_object = thing.instance()
	var disable = false
	if dice_roll > polygon_chance:
		mode = Modes.CIRCLE
	else:
		mode = Modes.POLYGON
	dice_roll = randf()
	if dice_roll < mobile_chance:
		mobile = true
	if current_state == States.SCREENS:
		disable = true
	spawn_object.position = Vector2(MIN_X + randi() % (MAX_X - MIN_X), MIN_Y + randi() % (MAX_Y - MIN_Y))
	spawn_object.init(mode, circle_radius, mobile, current_level, disable)
	$World.call_deferred("add_child", spawn_object)


func spawn_explosion(obj):
	var e = explosion.instance()
	e.position = obj.position
	if obj.mode == Modes.POLYGON:
		e.get_node("CPUParticles2D").texture = load("res://Assets/Sprites/Side.png")
		e.get_node("CPUParticles2D").scale_amount = 0.75
		e.get_node("CPUParticles2D").amount = obj.points.size()
	$World.call_deferred("add_child", e)

func spawn_combo(obj, count):
	var c = combo.instance()
	c.position = obj.position
	c.init(count, obj.color)
	$World.call_deferred("add_child", c)

func game_over():
	current_state = States.GAME_OVER
	$Timer.stop()
	for obj in $World.get_children():
		if obj.has_node("AnimationPlayer"):
			obj.get_node("AnimationPlayer").stop()
	$Screens.next_screen = $Screens.game_over_screen
	$Screens.switch_screen()
	
func reset():
	for obj in $World.get_children():
		obj.queue_free()
	fail_ratio = 0
	score = 0
	combo_counter = 0
	$HUD.update_labels($HUD.score_label, score)
	$HUD.update_labels($HUD.combo_label, combo_counter)
	$HUD.update_bars($HUD.fail_label, fail_ratio, fail_capacity)

func _on_SpawnObject_popped(obj):
	if current_state == States.PLAY:
		if obj.mode == Modes.CIRCLE:
			if obj.scale.x >= 0.8:
				combo_counter += 1
				if combo_counter > 1:
					spawn_combo(obj, combo_counter)
			else:
				combo_counter = 0
			score += floor(obj.scale.x * 100 + 10 * combo_counter)
			
			if score >= next_level:
				$Timer.wait_time = clamp($Timer.wait_time - 0.1, 0.3, 2.0)
				polygon_chance = clamp(polygon_chance + 0.025, 0.1, 0.25)
				mobile_chance = clamp(mobile_chance + 0.05, 0, 1)
				next_level = score + next_level * 1.1
				current_level += 1
				$HUD.advance_level(current_level)
				$Timer.stop()
		else:
			combo_counter = 0
			score = clamp(score - 250, 0, INF)
			fail_ratio += 15.0
			$AnimationPlayer.queue("Hurt")
			
		$HUD.update_labels($HUD.score_label, score)
		$HUD.update_labels($HUD.combo_label, combo_counter)
		$HUD.update_bars($HUD.fail_label, fail_ratio, fail_capacity)
		spawn_explosion(obj)
		if fail_ratio >= fail_capacity:
			game_over()
		

func _on_SpawnObject_perished(obj):
	if current_state == States.PLAY and obj.mode == Modes.CIRCLE:
		score = clamp(score - 50, 0, INF)
		combo_counter = 0
		fail_ratio += 5.0
		$HUD.update_labels($HUD.score_label, score)
		$HUD.update_bars($HUD.fail_label, fail_ratio, fail_capacity)
		$HUD.update_labels($HUD.combo_label, combo_counter)
		if fail_ratio >= fail_capacity:
			game_over()
	
func _on_Timer_timeout():
	spawn()


func _Start_game():
	reset()
	$Timer.stop()
	current_state = States.PLAY
	for obj in $World.get_children():
		obj.queue_free()
	yield(get_tree().create_timer(0.5), "timeout")
	$Timer.wait_time = 2
	$HUD.show_phrase()


func _on_Level_advanced():
	$Timer.start()


func _on_HUD_phrase_shown():
	yield(get_tree().create_timer(0.5), "timeout")
	$HUD.show()
	yield(get_tree().create_timer(0.75), "timeout")
	$HUD.advance_level(current_level)
	$Timer.start()


func _on_Screens_title_screen():
	$HUD.hide()
	for obj in $World.get_children():
		obj.queue_free()


func _on_Screens_restart():
	$HUD.hide()
	_Start_game()
	
