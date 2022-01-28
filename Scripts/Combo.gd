extends Node2D

onready var tween = $Tween


func _ready():
	tween.interpolate_property(self, "scale", Vector2.ZERO, Vector2(1, 1), 0.5, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "position", position, position - Vector2(0, 150), 2.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "modulate:a", 1, 0, 0.75,Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.75)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()

func init(count, object):
	match object.mode:
		object.Modes.POLYGON:
			$Label.text = "Ouch!"
		object.Modes.RAINBOW_CIRCLE:
			$Label.text = "Lucky!"
		object.Modes.CIRCLE:
			$Label.text = "Combo x%s" % count
	$Label.set("custom_colors/font_color", object.color)
	$Label.set_anchors_and_margins_preset(Control.PRESET_CENTER)
	position = object.position
