extends Position2D

onready var emitter = $CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func init(mode, color, size):
	if mode == 1:
		$CPUParticles2D.texture = load("res://Assets/Sprites/LineFragment.png")
		$CPUParticles2D.scale_amount = 0.75
		$CPUParticles2D.color = color
		$CPUParticles2D.hue_variation = 0
		$CPUParticles2D.amount = size
	elif mode == 2:
		$CPUParticles2D.texture = load("res://Assets/Sprites/RainbowCircle.png")
		$CPUParticles2D.color = Color(1, 1, 1)
		$CPUParticles2D.hue_variation = 0
	elif mode == 3:
		$CPUParticles2D.texture = load("res://Assets/Sprites/LineFragment.png")
		$CPUParticles2D.scale_amount = 1.5
		$CPUParticles2D.color = color
		$CPUParticles2D.hue_variation = 0
		$CPUParticles2D.amount = size		
	$CPUParticles2D.emitting = true


func _on_Timer_timeout():
	queue_free()
