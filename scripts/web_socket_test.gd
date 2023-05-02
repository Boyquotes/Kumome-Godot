extends SwapScene

var socket = WebSocketPeer.new()

var pinged := false

func _ready():

	#socket.handshake_headers = ['Authorization: %s' % Global.active_user.token]
	socket.connect_to_url('ws://127.0.0.1:3001')


func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not pinged:
			socket.send_text(JSON.stringify({'msg': 'ping'}))
			pinged = true

		while socket.get_available_packet_count():
			var response : PackedByteArray = socket.get_packet()
			print("Packet: ", (response.get_string_from_utf8()))
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
