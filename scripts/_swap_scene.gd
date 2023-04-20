extends Control
class_name SwapScene

signal swapped_to
signal opened_settings
signal generated_level
signal requested_level
signal quit
signal changed_quit_to


func none():
	pass

func goto(pos : Vector2, callback := none):
	(create_tween()
		.tween_property($camera, 'position', pos, 1.0)
		.set_trans(Tween.TRANS_CUBIC)
		.set_ease(Tween.EASE_IN_OUT)
	).connect('finished', callback)
