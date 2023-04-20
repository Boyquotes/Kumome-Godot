extends "res://scripts/avatar.gd"

func _ready():
	set_texture(texture)
	set_size(size)

	$dead.visible = false
	$thinking.visible = false

	emit_signal.call_deferred('finished')


func play_stuck():
	#await get_tree().create_timer(0.05).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	emit_signal.call_deferred('finished')
