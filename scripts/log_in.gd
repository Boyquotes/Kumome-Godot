extends SwapScene

@export var endpoint : String

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)

func _on_request_completed(_result, response_code, _headers, body : PackedByteArray):
	print(body.get_string_from_utf8())
	var data : Dictionary = (JSON.parse_string(body.get_string_from_utf8()))
	if response_code == 200:
		Global.log_in({'token' : data.data})
		swap_to_scene(preload("res://scenes/title.tscn"))
	else:
		$hold_on.visible = false

		var error = data.get('error', 'Unknown Error')
		print(error)
		$error/msg.text = error


func get_data() -> Dictionary:
	return {
		'email': $center/vbox/email.text,
		'password': $center/vbox/password.text
	}

func _on_create_an_account_pressed():
	swap_to_scene(preload("res://scenes/create_account.tscn"))

func _on_log_in_pressed():
	post(get_data(), endpoint)
