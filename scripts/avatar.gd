extends Node2D

signal finished

var size : Vector2 : set = set_size
var texture : Texture : set = set_texture

var stuck : bool :
	set(s):
		stuck = s
		if is_inside_tree():
			$thinking.visible = false
			if stuck:
				play_stuck()


var thinking : bool :
	set(t):
		thinking = t
		if is_inside_tree():
			$thinking.visible = t

func _ready():
	set_texture(texture)
	set_size(size)

	$dead.visible = false
	$thinking.visible = false

	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, 'rotation', 2*PI, 0.5)
	tween.tween_property(self, 'scale', Vector2.ONE, 0.5).from(Vector2.ZERO)
	tween.connect('finished', emit_signal.bind('finished'))

func destroy():
	var tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, 'rotation', 2*PI, 0.5)
	tween.tween_property(self, 'scale', Vector2.ZERO, 0.5).from(Vector2.ONE)
	tween.connect('finished', on_destroyed)

func on_destroyed():
	emit_signal('finished')
	queue_free.call_deferred()
	#tween.connect('finished', queue_free)

func play_stuck():
	$thinking.rotation = PI
	var tween = create_tween()
	tween.tween_property(self, 'position', position + Vector2.UP*size/4, 0.25)
	tween.tween_property(self, 'position', position, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback($dead.set.bind('visible', true))
	tween.connect('finished', on_stuck_animation_finished)

func set_size(s):
	size = s
	if not is_inside_tree() or texture == null: return

	for child in get_children():
		if child is Sprite2D:
			child.scale = size / texture.get_size()


func set_texture(tex : Texture):
	texture = tex
	if is_inside_tree():
		$Sprite2D.texture = texture

func move_to(pos : Vector2, callback : Callable):
	var tween = create_tween()
	tween.tween_property(self, 'position', pos, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(callback)

func on_stuck_animation_finished():
	emit_signal('finished')
