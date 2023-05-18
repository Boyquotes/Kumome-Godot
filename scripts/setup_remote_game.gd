extends SwapScene

var count : int
var player_pool := []

@onready var count_label = $count/HBoxContainer/count


func _ready():
	$Label2.text = Global.active_user.id + '\n'
	WS.connect('received', on_message_received)
	WS.connect('received_error', on_error_received)
	WS.connect('sent', on_message_sent)
	WS.connect_to_server()
	$Button.disabled = not WS.is_connected
	inc_count(0)

func on_error_received(code : String, error : Dictionary):
	show_msg(code, error, 'RED')

func on_message_sent(code : String, data : Dictionary):
	show_msg(code, data, 'GREEN')

func on_message_received(event : String, data : Dictionary):
	show_msg(event, data, 'GRAY')

	if event == WS.rCONNECTED:
		$Button.disabled = data.get('playerId') == Global.active_user.id
		$Label.text = ''

	elif event == WS.rJOINED:
		WS.game_id = data.get('gameId')
		print('Game ID: ', WS.game_id)
		var player_id = data.get('playerId')
		prints('id', player_id, data.get('username'))
		var start := add_player(player_id)
		if start:
			WS.send(WS.sGAME_START, {}, true)
			start_game(data)



	elif event == WS.rGAME_STARTED:
		start_game(data)


	else:
		print(event, data.keys())

func start_game(data : Dictionary):
	var board = Global.create_remote_game(data.get('board', []), data.get('gameId', ''))
	emit_signal('generated_level', board)
	swap_to_scene(preload("res://scenes/play.tscn"))

func show_msg(event : String, data : Dictionary, color := 'WHITE'):
	$Label2.text += '[color=%s] %s %s [/color]\n' % [color, event, data.get('username', '')]

func _on_button_pressed():
	WS.send(WS.sJOIN, {'boardId': 'traditional-1-%s' % count}, false)
	#WS.send(WS.sJOIN, {'boardId': 'test-1-2'}, false)

	$Button.disabled = true

	for child in $count/HBoxContainer.get_children():
		child.set('disabled', true)

func add_player(id) -> bool:
	if id in player_pool:
		return len(player_pool) == count

	player_pool.append(id)
	var number_of_players = len(player_pool)
	prints('players:', number_of_players, 'of', count)
	$Label.text = 'Waiting for players (%s/%s)' % [number_of_players, count]
	return number_of_players == count

func inc_count(dir : int):
	count = clampi(count + dir, 2, 4)
	count_label.text = str(count)

func _on_raise_pressed():
	inc_count(1)


func _on_lower_pressed():
	inc_count(-1)
