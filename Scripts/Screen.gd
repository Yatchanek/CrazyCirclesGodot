extends CanvasLayer


onready var tween = $Tween
# Called when the node enters the scene tree for the first time.
	
func disappear():
	$Tween.interpolate_property(self, "offset:x", 0, 500, 0.75, Tween.TRANS_BACK, Tween.EASE_OUT)
	$Tween.start()

func appear():
	$Tween.interpolate_property(self, "offset:x", 500, 0, 0.75, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	$Tween.start()



func _on_Play_mouse_entered():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer/PlayLabel.set("custom_colors/font_color", Color(0.53, 0.13, 0.13))


func _on_Play_mouse_exited():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer/PlayLabel.set("custom_colors/font_color", Color(1, 1, 1))


func _on_Options_mouse_entered():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer2/OptionsLabel.set("custom_colors/font_color", Color(0.53, 0.13, 0.13))


func _on_Options_mouse_exited():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer2/OptionsLabel.set("custom_colors/font_color", Color(1, 1, 1))


func _on_Help_mouse_entered():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer3/HelpLabel.set("custom_colors/font_color", Color(0.53, 0.13, 0.13))


func _on_Help_mouse_exited():
	$MarginContainer/VBoxContainer2/CenterContainer/VBoxContainer/VBoxContainer3/HelpLabel.set("custom_colors/font_color", Color(1, 1, 1))
