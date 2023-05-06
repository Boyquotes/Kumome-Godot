extends SwapScene

func _ready():
	$Label2.text = Global.active_user.id + '\n'
	WS.connect('received', on_message_received)
	WS.connect_to_server()
	$Button.disabled = not WS.is_connected


func on_message_received(event : String, data : Dictionary):
	$Label2.text += event + data.get('playerId', '') + '\n'

	if event == WS.rCONNECTED:
		$Button.disabled = false
		$Label.text = ''

	elif event == WS.rJOINED:
		WS.game_id = data.get('gameId')
		var player_id = data.get('playerId')
		if player_id != Global.active_user.id:
			WS.send(WS.sGAME_START, {}, true)
			start_game(data)

		else:
			$Label.text = 'Waiting for opponent...'

	elif event == WS.rGAME_STARTED:
		start_game(data)


	else:
		print(event, data.keys())

func start_game(data : Dictionary):
	var board = Global.create_remote_game(data.get('board', []), data.get('gameId', ''))
	emit_signal('generated_level', board)
	swap_to_scene(preload("res://scenes/play.tscn"))

func _on_button_pressed():
	WS.send(WS.sJOIN, {'boardId': 'traditional-1-2'}, false)
	$Button.disabled = true
