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

func swap_to_scene(ps : PackedScene):
	emit_signal("swapped_to", ps)

func post(data : Dictionary, endpoint : String, http_request = null):
	#prints('post', data, endpoint)
	var json = JSON.stringify(data)
	var header = ['Content-Type: application/json']
	$hold_on.visible = true
	if http_request == null:
		http_request = $HTTPRequest
	http_request.request(Global.url + endpoint, header, HTTPClient.METHOD_POST, json)
