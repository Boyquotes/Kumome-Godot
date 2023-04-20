extends Node2D

var id : String : set = set_id
var old_id : String
var location : Vector2i
var size : Vector2 : set = set_size

func _ready():
	shrink()

func shrink():
	var tween := create_tween()
	tween.tween_property(self, 'scale', Vector2.ZERO, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(change_texture)

func grow():
	var tween := create_tween()
	tween.tween_property(self, 'scale', size / $Sprite2D.texture.get_size() , 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func change_texture():
	if id in ['none', '']:
		return
	elif id == 'player':
		$Sprite2D.texture = preload("res://imgs/happy.png")
	elif id == 'bot':
		$Sprite2D.texture = preload("res://imgs/bot.png")
	elif id == 'mine':
		$Sprite2D.texture = preload("res://imgs/mine.png")
	else:
		push_warning('BAD ID')

	grow()


func set_size(s):
	size = s
	if not is_inside_tree() or $Sprite2D.texture == null: return

	for child in get_children():
		if child is Sprite2D:
			child.scale = size / $Sprite2D.texture.get_size()

func set_id(_id):
	old_id = id
	id = _id
	if not is_inside_tree() or old_id == id: return
	if old_id == 'none':
		change_texture()
	else:
		shrink()
