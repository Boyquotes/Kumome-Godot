@tool
extends Area2D

signal touched

@export_enum ('player', 'bot', 'mine', 'arrow') var id : String = 'player' : set = set_id
var home_scale : Vector2

func _ready():
	set_id(id)
	home_scale = scale

func on_touched():
	emit_signal('touched', id)
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, 'scale', 1.2*home_scale, 0.1)
	tween.tween_property(self, 'scale', home_scale, 0.1)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventScreenTouch and event.pressed:
		on_touched()

func set_id(_id):
	id = _id
	if not is_inside_tree(): return

	var tex : Texture
	if id == 'player':
		tex = preload("res://imgs/happy.png")
	elif id == 'bot':
		tex = preload("res://imgs/bot.png")
	elif id == 'mine':
		tex = preload("res://imgs/mine.png")
	elif id == 'arrow':
		tex = preload("res://imgs/arrow.png")
	$Sprite2D.texture = tex
