extends SwapScene

@export var list_endpoint : String
@export var add_endpoint : String

var header = ['Content-Type: application/json', 'Authorization: %s' % Global.active_user.token]


func _ready():
	$requests/list.request_completed.connect(on_request_completed.bind(on_list_request_completed))
	$requests/add.request_completed.connect(on_request_completed.bind(on_add_request_completed))

	get_friend_list()

func on_request_completed(_result, response_code, _headers, body : PackedByteArray, callback : Callable):
	var data : Dictionary = (JSON.parse_string(body.get_string_from_utf8()))
	if response_code == 200 or response_code == 201:
		callback.call(data)
	else:
		$hold_on.visible = false

		var error = data.get('error', data.get('message', 'Unknown Error'))
		prints('error', data, error)
		$error/msg.text = error

func on_list_request_completed(data : Dictionary):
	update_friend_list(data)

func on_add_request_completed(data : Dictionary):
	print(data)


func update_friend_list(data : Dictionary):
		var label = Label.new()
		label.text = str(data)
		$CenterContainer/VBoxContainer.add_child(label)


func get_friend_list():
	$requests/list.request(Global.url + list_endpoint, header, HTTPClient.METHOD_GET)

func _on_add_pressed():
	var dict = {
		"requester": Global.active_user.id,
		"recipient": $friend_token.text
	}

	$requests/add.request(
		Global.url + add_endpoint,
		header,
		HTTPClient.METHOD_POST,
		JSON.stringify(dict)
	)
