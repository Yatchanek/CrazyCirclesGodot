extends Area2D

onready var game_manager = get_parent().get_parent()

export (Array, Color) var colors

export var min_vertices = 4
export var max_vertices = 6

signal popped
signal perished
signal inner_popped

var moving = false
var velocity = Vector2.ZERO
var mode
var initial_mode
var radius = 100
var color
var is_disabled
var rotation_speed
var rotation_dir
var popped = false
var paused = false
var vertices = 0
var value

enum Modes {
	CIRCLE,
	POLYGON,
	RAINBOW_CIRCLE,
	DOUBLE_CIRCLE
}

	
func draw_thick_polygon():
	vertices = min_vertices + randi() % (max_vertices - min_vertices)
	var angle_fraction = TAU / vertices
	
	for i in range(vertices + 1):
		var p = Vector2(radius * cos(i * angle_fraction - 90), radius * sin(i * angle_fraction - 90))
		$Line2D.add_point(p)
		
	$Line2D.default_color = color

func _ready():
	randomize()
	color = colors[randi() % colors.size()]
	rotation_speed = rand_range(PI, TAU)
	rotation_dir = pow(-1, randi() % 2)
	if mode == Modes.CIRCLE:
		$Sprite.modulate = color
		value = 100
		
	elif mode == Modes.RAINBOW_CIRCLE:
		$Sprite.hide()
		$RainbowSprite.show()
		value = 125
	
	elif mode == Modes.DOUBLE_CIRCLE:
		$InnerSprite.show()
		$Sprite.modulate = color
		color = colors[randi() % colors.size()]
		$InnerSprite.modulate = color
		value = 200
		
	else:
		draw_thick_polygon()
		$Sprite.hide()

	var _err = connect("popped", game_manager, "_on_SpawnObject_popped")
	_err = connect("perished", game_manager, "_on_SpawnObject_perished")
	_err = connect("inner_popped", game_manager, "_on_SpawnObject_inner_popped")
	
func init(obj_type, mobile, level, disable, diff):
	mode = obj_type
	initial_mode = mode
	is_disabled = disable
	match diff:
		1:
			min_vertices = 4
			max_vertices = 6
		2:
			min_vertices = 5
			max_vertices = 7
		3:
			min_vertices = 5
			max_vertices = 8
	if mobile:
		velocity = Vector2(rand_range(25, 50), rand_range(25, 50)) * diff
		moving = true

	var anim_speed = clamp(1 + 0.015 * diff * (level - 1), 1, 2)
	$AnimationPlayer.set_speed_scale(anim_speed)


func _process(delta):
	if !paused:
		rotation += rotation_speed * rotation_dir * delta
		$InnerSprite.rotation -= 2 * rotation_speed * rotation_dir * delta
		rotation_speed += 0.01
		
		if moving:
			position += velocity * delta

			if position.x < radius or position.x > 450 - radius:
				velocity.x *= -1
			if position.y < radius + 150 or position.y > 900 - radius:
				velocity.y *= -1

func _unhandled_input(event):
	if !popped and !is_disabled and !paused:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				var mouse_pos = get_local_mouse_position()
				if [Modes.CIRCLE, Modes.DOUBLE_CIRCLE, Modes.RAINBOW_CIRCLE].has(mode):
					if mouse_pos.distance_squared_to(Vector2.ZERO) < radius * radius:
						get_tree().set_input_as_handled()	
						if mode == Modes.DOUBLE_CIRCLE:
							mode = Modes.CIRCLE
							$InnerSprite.hide()
							emit_signal("inner_popped", self)
							$SmallExplosion.emitting = true
						else:
							popped = true
							$Sprite.hide()
							$RainbowSprite.hide()
							emit_signal("popped", self)
							$BigExplosion.emitting = true
							$AnimationPlayer.stop()
							yield(get_tree().create_timer(0.85), "timeout")
							queue_free()
						
				else:
					if Geometry.is_point_in_polygon(mouse_pos, $Line2D.points):
						popped = true
						get_tree().set_input_as_handled()	
						emit_signal("popped", self)
						$Line2D.hide()
						$BigExplosion.texture = load("res://Assets/Sprites/LineFragment.png")
						$BigExplosion.amount = vertices * 3
						$BigExplosion.color = color
						$BigExplosion.hue_variation = 0
						$BigExplosion.scale_amount = 0.5
						$BigExplosion.emitting = true
						$AnimationPlayer.stop()
						yield(get_tree().create_timer(0.85), "timeout")
						queue_free()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Shrink":
		emit_signal("perished", self)
		queue_free()
