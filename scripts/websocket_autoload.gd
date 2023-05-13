extends Node

var url = 'ws://' + Global.base_url

# Receive
const rCONNECTED = 'connected'
const rJOINED = 'freeForAll/joined'
const rGAME_STARTED = 'freeForAll/gameStarted'
const rGAME_UPDATED = 'freeForAll/gameUpdated'
const rTURN_SET = 'freeForAll/turnSet'

# Send
const sJOIN = "freeForAll/onJoin"
const sGAME_START = "freeForAll/onGameStart"
const sGAME_UPDATE = "freeForAll/onGameUpdate"
const sLEAVE = "freeForAll/onLeave"
const sGAME_OVER = "freeForAll/onGameOver"

signal connected
signal received
signal received_error
signal sent

var socket = WebSocketPeer.new()
var is_connected := false
var is_polling := false
var game_id : String


func connect_to_server():
	if is_connected:
		return

	socket.connect_to_url('%s/?token=%s' % [url, Global.active_user.token])
	is_polling = true

func _process(_delta):
	if not is_polling:
		return

	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected:
			emit_signal('connected')
			is_connected = true

		while socket.get_available_packet_count():
			var raw_response : PackedByteArray = socket.get_packet()
			var response = JSON.parse_string(raw_response.get_string_from_utf8())

			if response.get('type', 'error') == 'data':
				var data = response.get('data', {})
				emit_signal('received', data.get('event', ''), data.get('data', {}))
			else:
				var error = response.get('error', {})
				emit_signal('received_error', error.get('code'), error)
				push_warning('error! ', error)

	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		is_connected = false
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func send(event : String, data : Dictionary, with_game_id : bool):
	if with_game_id:
		data['gameId'] = game_id

	emit_signal('sent', event, data)
	socket.send_text(JSON.stringify({
		"event": event,
		"data": data
	}))

func send_board_update(action: int, card: int, current: String, next : String, game : String, board: Array):
	var data = {
		"actionKey": action,
		"cardKey": card,
		"currentPlayerId": current,
		"gameId": game,
		"nextPlayerId": next,
		"updatedBoard": board
	}

	send(sGAME_UPDATE, data, false)
