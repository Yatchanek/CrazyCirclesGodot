extends CanvasLayer

onready var score_label = $MarginContainer/VBoxContainer/HBoxContainer/ScoreLabel
onready var level_label = $LevelLabel
onready var combo_label = $MarginContainer/VBoxContainer/HBoxContainer2/ComboLabel
onready var fail_label = $ProgressBars/VBoxContainer2/HBoxContainer/FailProgress


signal level_advanced
signal phrase_shown

var hidden = false
var blinking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	fail_label.max_value = get_parent().fail_capacity

func update_labels(label, value):
	label.text = "%s" % value
	
func update_bars(bar, value, max_value):
	bar.value = value
	var ratio = value / max_value
	
	bar.tint_progress = Color.green
	if ratio > 0.3:
		bar.tint_progress = Color.yellow
	if ratio > 0.6:
		bar.tint_progress = Color.red
	if ratio > 0.8:
		if !blinking:
			blink()
			blinking = true
	else:
		blinking = false
		
func blink():
	$Tween.interpolate_property(fail_label.texture_progress, "modulate:a", 1, 0, 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property(fail_label.texture_progress, "modulate:a", 1, 0, 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.25)
	$Tween.repeat = true
	$Tween.start()
	
func advance_level(level):
	level_label.text = "Level %s" % level
	$AnimationPlayer.play("ShowLevel")

func show_phrase():
	$AnimationPlayer.play("Show Phrase")

func hide():
	$Tween.stop_all()
	$Tween.repeat = false
	if !hidden:
		$Tween.interpolate_property($MarginContainer, "modulate:a", 1, 0, 0, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property($ProgressBars, "modulate:a", 1, 0, 0, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		hidden = true
	
func show():
	$Tween.stop_all()
	$Tween.repeat = false
	if hidden:
		$Tween.interpolate_property($MarginContainer, "modulate:a", 0, 1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property($ProgressBars, "modulate:a", 0, 1, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
		hidden = false

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "ShowLevel":
		emit_signal("level_advanced")
	if anim_name == "Show Phrase":
		emit_signal("phrase_shown")
