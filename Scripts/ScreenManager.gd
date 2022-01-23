extends Node

onready var title_screen = $TitleScreen
onready var info_screen = $InstructionScreen
onready var game_over_screen = $GameOverScreen
onready var options_screen = $OptionsScreen
var arrow_cursor = preload("res://Assets/Menu Icons/upLeft.png")

signal new_game
signal title_screen
signal restart

var current_screen
var next_screen

func _ready():
	for button in get_tree().get_nodes_in_group("Buttons"):
		button.connect("pressed", self, "_on_Button_pressed", [button.name])
	current_screen = title_screen

func switch_screen():
	if current_screen:
		current_screen.disappear()
		yield(current_screen.tween, "tween_completed")
	if next_screen:
		next_screen.appear()
		yield(next_screen.tween, "tween_completed")
	
	current_screen = next_screen
	next_screen = null
	
func _on_Button_pressed(name):
	match name:
		"Play":
			next_screen = null
			switch_screen()
			emit_signal("new_game")
		"Options":
			next_screen = options_screen
			switch_screen()
		"Back":
			next_screen = title_screen
			switch_screen()
		"Help":
			next_screen = info_screen
			switch_screen()
		"Home":
			next_screen = title_screen
			emit_signal("title_screen")
			switch_screen()
			Input.set_custom_mouse_cursor(arrow_cursor)
		"Restart":
			next_screen = null
			switch_screen()
			emit_signal("restart")
