extends Position2D

onready var emitter = $CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	init()
	yield(get_tree().create_timer(0.8), "timeout")
	queue_free()

func init():
	$CPUParticles2D.emitting = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
