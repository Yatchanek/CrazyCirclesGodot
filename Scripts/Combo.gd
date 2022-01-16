extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Tween.interpolate_property($Label, "modulate:a", 1, 0, 0.5,Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.5)
	$Tween.start()
	yield($Tween, "tween_completed")
	queue_free()

func init(count, color):
	$Label.text = "Combo x%s" % count
	$Label.modulate = color
	$Label.set_anchors_and_margins_preset(Control.PRESET_CENTER)
