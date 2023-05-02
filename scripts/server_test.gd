extends SwapScene

@export var endpoint : String

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)

func _on_request_completed(_result, response_code, _headers, body : PackedByteArray):
	var data : Dictionary = (JSON.parse_string(body.get_string_from_utf8()))
	if response_code == 201:
		prints('DATA', data)
		Global.log_in({'token': data.token})
		swap_to_scene(preload("res://scenes/title.tscn"))
	else:
		$hold_on.visible = false
		var error = data.get('error', 'Unknown Error')
		$error/msg.text = error


func get_data() -> Dictionary:
	return {
		'email': $center/vbox/email.text,
		'password': $center/vbox/password.text,
		'username': $center/vbox/username.text
	}


func _on_submit_pressed():
	var data = get_data()
	post(data, endpoint)


func _on_log_in_pressed():
	swap_to_scene(preload("res://scenes/log_in.tscn"))
