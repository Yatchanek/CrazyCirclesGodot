extends CanvasLayer


onready var tween = $Tween
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func disappear():
	$Tween.interpolate_property(self, "offset:x", 0, 500, 0.75, Tween.TRANS_BACK, Tween.EASE_OUT)
	$Tween.start()

func appear():
	$Tween.interpolate_property(self, "offset:x", 500, 0, 0.75, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	$Tween.start()

