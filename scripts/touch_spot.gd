extends Node2D

signal touched

var size : Vector2 = Vector2(100, 100) : set = set_size
var location : Vector2i

func _ready():
	set_size(size)
	create_tween().tween_property(self, 'scale', scale, 0.3).from(Vector2.ZERO).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func _process(delta):
	rotation += delta

func set_size(s):
	size = s
	if is_inside_tree():
		scale = size / $Sprite2D.texture.get_size()


func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch and event.pressed:
		emit_signal('touched', location)
