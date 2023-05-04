extends Player
class_name  PlayerRemote

const p1 = '644efdf32044812abebcea64'

var next_player_id : String :
	set(x):
		if id == p1:
			print('>>> ', x)
		next_player_id = x

func _init(_theme : Global.AVATARS, _team : int, _id : String):
	super(_theme, _team, _id)
	WS.connect('received', receive)
	connect('finished', on_action_finished)

func play_card():
	add_card(CardDummy.new({}))

func receive(event : String, data : Dictionary):
	if event == WS.rGAME_UPDATED and data.get('currentPlayerId', '') == id:
		do_action(data.get('actionKey', 0), data.get('updatedBoard', []))
		next_player_id = data.get('nextPlayerId', '')


func do_action(action_key : int, board : Array):
	var parsers := {
		Global.ACTIONS.MOVE : parse_move,
		Global.ACTIONS.MINE : parse_mine
	}

	difference(game.export_board(), board, parsers.get(action_key, parse_invalid))

func on_action_finished():
	if id == p1:
		prints(id, 'action finished', next_player_id)
	if next_player_id != id:
		emit_signal('card_finished')


func difference(b1 : Array, b2 : Array, parser : Callable):
	var diffs := []
	for i in range(1, len(b1)):
		for j in range(1, len(b1[i])):
			if b1[i][j] != b2[i][j]:
				diffs.append({
					'x': i-1,
					'y': j-1,
					'old': b1[i][j],
					'new': b2[i][j]
				})

	parser.call(diffs)

func parse_move(args : Array):
	var old
	var new
	if len(args) != 2:
		on_invalid_move()
		return

	for arg in args:
		if not arg is Dictionary:
			on_invalid_move()
			return

		if arg.get('new', '') == '0':
			old = arg

		if arg.get('old', '') == '0':
			new = arg

	if old == null or new == null:
		on_invalid_move()
		return

	if maxi(abs(old.x - new.x), abs(old.y - new.y)) != 1:
		on_invalid_move()
		return

	move_to(Vector2i(new.x, new.y))

func parse_mine(args : Array):
	if len(args) != 1:
		on_invalid_move()
		return

	var spot = args[0]
	if spot.old == '0' and spot.new == 'x':
		place_at(Vector2i(spot.x, spot.y))
	else:
		on_invalid_move()

func parse_invalid(_args):
	on_invalid_move()



func on_invalid_move():
	push_warning('bad move')
	await avatar.get_tree().process_frame
	await avatar.get_tree().process_frame
	emit_signal('finished')

func send_action(_a):
	pass
