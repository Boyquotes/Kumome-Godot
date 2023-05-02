@tool
extends Control
class_name GameBoard

@export var dimensions : Vector2i = Vector2i(8, 8):
	set(dim):
		dimensions = dim
		refresh()

@export var colors : Array[Color] = [Color(0, 0.66, 0.66), Color(0.51, 0.55, 0.85)]:
	set(cols):
		colors = cols
		refresh()

var square_size : Vector2 :
	get:
		return size / Vector2(dimensions)

func _ready():
	refresh()

func refresh():
	if not is_inside_tree():
		return

	for child in get_children():
		child.queue_free()


	for col in dimensions.x:
		for row in dimensions.y:
			var square = preload("res://scenes/square.tscn").instantiate()
			square.position = Vector2(col, row) * square_size
			square.set_deferred('size', square_size)
			square.color = colors[(col + row) % len(colors)]
			add_child(square)

func to_position(location : Vector2i) -> Vector2:
	return position + (Vector2(location) + Vector2(0.5, 0.5)) * square_size

func _on_resized():
	refresh()
