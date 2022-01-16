extends Area2D

onready var game_manager = get_parent().get_parent()

export (Array, Color) var colors

signal circle_popped
signal circle_perished

var moving
var velocity = Vector2.ZERO

func _ready():
	randomize()
	$Sprite.modulate = colors[randi() % colors.size()]
	connect("circle_popped", game_manager, "_on_Circle_popped")
	connect("circle_perished", game_manager, "_on_Circle_perished")
	
func init(radius, mobile, level):
	$CollisionShape2D.shape.radius = radius
	if mobile:
		velocity = Vector2(rand_range(50, 100), rand_range(50, 100))
		moving = true
	else:
		moving = false
	var anim_speed = clamp(1 + 0.1 * (level - 1), 1, 2)
	$AnimationPlayer.set_speed_scale(1 + 0.1 * (level - 1))


func _process(delta):
	rotation += 5 * delta
	if moving:
		position += velocity * delta
		if position.x < 100 or position.x > get_viewport().size.x - 100:
			velocity.x *= -1
		if position.y < 100 or position.y > get_viewport().size.y - 100:
			velocity.y *= -1


func _on_Circle_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT) or event is InputEventScreenTouch:
		$CollisionShape2D.set_deferred("disabled", true)
		emit_signal("circle_popped", self)
		queue_free()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shrink":
		emit_signal("circle_perished")
		queue_free()
