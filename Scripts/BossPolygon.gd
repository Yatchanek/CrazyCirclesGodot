extends Area2D

var polygon_points : PoolVector2Array
var active_vertices
export var rotation_speed = PI
var explosion = preload("res://Scenes/Explosion.tscn")
var destroyed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	active_vertices = $Vertices.get_children()
	var angle_fraction = TAU / 8
	for i in range(9):
		var p = Vector2(200 * cos(i * angle_fraction), 200 * sin(i * angle_fraction))
		polygon_points.push_back(p)
		if i < 8:
			$Vertices.get_child(i).position = p
	$Line2D.points = polygon_points
	$VertexTimer.wait_time = rand_range(0.5, 1.5)
	$VertexTimer.start()

func switch_direction():
	$Tween.interpolate_property(self, "rotation_speed", rotation_speed, - rotation_speed, 1.0, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	$Tween.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !destroyed:
		rotation += rotation_speed * delta


func restart_timer():
	$VertexTimer.wait_time = rand_range(0.5, 1.5)
	$VertexTimer.start()
	
func _on_Vertex_disappeared():
	restart_timer()


func _on_Vertex_destroyed(vertex):
	active_vertices.erase(vertex)
	if active_vertices.size() > 0:
		restart_timer()
		rotation_speed *= 1.1
	else:
		destroyed = true
		rotation_speed = 0
		for vertex in $Vertices.get_children():
			vertex.destroy()
		var e = explosion.instance()
		e.init(3, $Line2D.default_color, 8)
		e.position = position
		get_parent().add_child(e)
		$Line2D.hide()
		yield(get_tree().create_timer(3), "timeout")
		queue_free()

func _on_Timer_timeout():
	switch_direction()


func _on_VertexTimer_timeout():
	active_vertices[randi() % active_vertices.size()].appear()
