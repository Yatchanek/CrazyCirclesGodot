extends Area2D

onready var game_manager = get_parent().get_parent()

export (Array, Color) var colors

export var min_vertices = 4
export var max_vertices = 6

signal popped
signal perished

var moving
var velocity = Vector2.ZERO
var mode
export var radius = 100
var points : PoolVector2Array
var color
var is_disabled
var rotation_speed
var rotation_dir
var popped = false

enum Modes {
	CIRCLE,
	POLYGON,
	RAINBOW_CIRCLE
}

	
func draw_thick_polygon():
	var vertices = min_vertices + randi() % (max_vertices - min_vertices)
	var angle_fraction = TAU / vertices
	
	for i in range(vertices + 1):
		var p = Vector2(radius * cos(i * angle_fraction - 90), radius * sin(i * angle_fraction - 90))
		points.push_back(p)
		
	$Line2D.points = points
	$Line2D.default_color = color

func _ready():
	randomize()
	color = colors[randi() % colors.size()]
	rotation_speed = rand_range(PI, TAU)
	rotation_dir = pow(-1, (randi() % 2 + 1))
	if mode == Modes.CIRCLE:
		$Sprite.modulate = color
		
	elif mode == Modes.RAINBOW_CIRCLE:
		$Sprite.hide()
		$RainbowSprite.show()
		
	else:
		draw_thick_polygon()
		$CollisionPolygon2D.polygon = points
		$Sprite.hide()



	connect("popped", game_manager, "_on_SpawnObject_popped")
	connect("perished", game_manager, "_on_SpawnObject_perished")
	
func init(obj_type, mobile, level, disable, diff):
	mode = obj_type
	is_disabled = disable
	if mobile:
		velocity = Vector2(rand_range(25, 50), rand_range(25, 50)) * diff
		moving = true
	else:
		moving = false
	var anim_speed = clamp(1 + 0.025 * diff* (level - 1), 1, 2)
	$AnimationPlayer.set_speed_scale(anim_speed)


func _process(delta):
	rotation += rotation_speed * rotation_dir * delta
	rotation_speed += 0.01

	if moving:
		position += velocity * delta

		if position.x < radius or position.x > 450 - radius:
			velocity.x *= -1
		if position.y < radius + 150 or position.y > 900 - radius:
			velocity.y *= -1

func _unhandled_input(event):
	if !popped and !is_disabled:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				var mouse_pos = get_local_mouse_position()
				if mode == Modes.CIRCLE or mode == Modes.RAINBOW_CIRCLE:
					if mouse_pos.distance_squared_to(Vector2.ZERO) < radius * radius:
						popped = true
						get_tree().set_input_as_handled()	
						emit_signal("popped", self)
						queue_free()	
				else:
					var polygon = $CollisionPolygon2D.polygon
					if Geometry.is_point_in_polygon(mouse_pos, polygon):
						popped = true
						get_tree().set_input_as_handled()	
						emit_signal("popped", self)
						queue_free()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shrink":
		emit_signal("perished", self)
		queue_free()
