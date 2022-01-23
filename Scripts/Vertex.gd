extends Sprite

var popped = false
var active = false
var radius = 100
var rotation_speed
var destroyed = false
var velocity = Vector2.ZERO
var explosion = preload("res://Scenes/Explosion.tscn")

signal destroyed
signal disappeared

export (Array, Color) var colors

func _unhandled_input(event):
	if !popped and active:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				var mouse_pos = get_local_mouse_position()
				if mouse_pos.distance_squared_to(Vector2.ZERO) < radius * radius:
					self.modulate = Color(1,0,0)
					$Timer.stop()
					active = false
					emit_signal("destroyed")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	connect("disappeared", get_parent().get_parent(), "_on_Vertex_disappeared")
	connect("destroyed", get_parent().get_parent(), "_on_Vertex_destroyed", [self])
	rotation_speed = rand_range(PI / 2, PI) * pow(-1, randi() % 2 + 1)
	modulate = colors[randi() % colors.size()]

func _process(delta):
	rotation += rotation_speed * delta
	if destroyed:
		position += velocity * delta

func appear():
	$Tween.interpolate_property(self, "scale", Vector2(0,0), Vector2(0.5,0.5), 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.start()
	
func disappear():
	active = false
	$Tween.interpolate_property(self, "scale", Vector2(0.5,0.5), Vector2(0,0), 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.start()

func destroy():
	destroyed = true
	velocity = Vector2(rand_range(-300, 300), rand_range(-300, 300))
	$Timer.wait_time = rand_range(1, 2)
	$Timer.start()

func _on_Timer_timeout():
	if !destroyed:
		disappear()
	else:
		var e = explosion.instance()
		e.position = position
		get_parent().get_parent().add_child(e)
		e.init(0, modulate, 32)
		queue_free()

func _on_Tween_tween_all_completed():
	visible = !visible
	if !visible:
		
		emit_signal("disappeared")
	else:
		active = true
		$Timer.wait_time = rand_range(0.75, 0.9)
		$Timer.start()

