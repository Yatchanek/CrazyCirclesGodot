extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Tween.interpolate_property(self, "scale", Vector2.ZERO, Vector2(1, 1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	$Tween.interpolate_property(self, "modulate:a", 1, 0, 0.75,Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.75)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	queue_free()

func init(count, color):
	$Label.text = "Combo x%s" % count
	$Label.modulate = color
	$Label.set_anchors_and_margins_preset(Control.PRESET_CENTER)
