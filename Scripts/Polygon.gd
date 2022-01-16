extends Area2D

onready var game_manager = get_parent().get_parent()

var points : PoolVector2Array
export (Array, Color) var colors
export var min_vertices = 4
export var max_vertices = 8
export var radius = 100
var color

signal polygon_caught

func _draw():
	draw_thick_polygon()
	$CollisionPolygon2D.polygon = points

func _ready():
	randomize()
	color = colors[randi() % colors.size()]
	connect("polygon_caught", game_manager, "_on_Polygon_caught")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation += 5 * delta


func _on_Polygon_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT) or event is InputEventScreenTouch:
		emit_signal("polygon_caught")
		queue_free()
