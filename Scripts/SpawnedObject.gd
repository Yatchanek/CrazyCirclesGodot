extends Area2D

onready var game_manager = get_parent().get_parent()

export (Array, Color) var colors

export var min_vertices = 4
export var max_vertices = 8

signal popped
signal perished

var moving
var velocity = Vector2.ZERO
var mode
var radius
var points : PoolVector2Array
var color
var is_disabled

enum Modes {
	CIRCLE,
	POLYGON
}

func _draw():
	if mode == Modes.POLYGON:
		draw_thick_polygon()
		$CollisionShape.polygon = points

func draw_thick_polygon():
	var vertices = min_vertices + randi() % (max_vertices - min_vertices)
	var angle_fraction = 2 * PI / vertices
	
	for i in range(vertices + 1):
		var p = Vector2(radius * cos(i * angle_fraction), radius * sin(i * angle_fraction))
		points.push_back(p)
		
	for i in range(vertices):
		draw_line(points[i], points[i + 1], color, 20.0, true)

func _ready():
	randomize()
	var cs
	color = colors[randi() % colors.size()]
	if mode == Modes.CIRCLE:
		cs = CollisionShape2D.new()
		cs.shape = CircleShape2D.new()
		$Sprite.modulate = color
		cs.shape.radius = radius
	else:
		$Sprite.hide()
		cs = CollisionPolygon2D.new()
	cs.name = "CollisionShape"	
	add_child(cs)
	connect("popped", game_manager, "_on_SpawnObject_popped")
	connect("perished", game_manager, "_on_SpawnObject_perished")
	
func init(obj_type, rad, mobile, level, disable):
	radius = rad
	mode = obj_type
	is_disabled = disable
	if mobile:
		velocity = Vector2(rand_range(50, 100), rand_range(50, 100))
		moving = true
	else:
		moving = false
	var anim_speed = clamp(1 + 0.05 * (level - 1), 1, 2)
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
	if !is_disabled:
		if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT) or event is InputEventScreenTouch:
			$CollisionShape.set_deferred("disabled", true)
			emit_signal("popped", self)
			queue_free()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shrink":
		emit_signal("perished", self)
		queue_free()
