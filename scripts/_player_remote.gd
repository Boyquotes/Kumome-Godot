extends Player
class_name  PlayerRemote

var next_player_id : String

class Diff:
	var old : String
	var new : String
	var loc : Vector2i
	var valid : bool
	func _init(_old := '', _new := '', x := 0, y := 0):
		valid = true
		old = _old
		new = _new
		loc = Vector2i(x, y)
	func invalid():
		valid = false
		return self
	func _to_string():
		return '< %s, %s, %s >' % [old, new, loc] if valid else '< invalid >'

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
	var act : int = action_key % 256
	var parsers := {
		Global.actions.move : parse_move,
		Global.actions.mine : parse_mine,
		Global.actions.teleport : parse_teleport,
		Global.actions.charge : parse_charge,
		Global.actions.unmine : parse_unmine,
		Global.actions.target : parse_target,
		Global.actions.swap : parse_swap,
		Global.actions.invisible : parse_invisible
	}

	#prints(action_key, act, parsers.keys(), typeof(parsers.keys()[0]), typeof(act))

	difference(game.export_board(), board, parsers.get(act, parse_invalid), action_key)

func on_action_finished():
	if next_player_id != id:
		emit_signal('card_finished')


func difference(b1 : Array, b2 : Array, parser : Callable, action_key : int):
	var diffs : Array[Diff] = []
	for i in range(1, len(b1)):
		for j in range(1, len(b1[i])):
			if b1[i][j] != b2[i][j]:
				diffs.append(Diff.new(b1[i][j], b2[i][j], i-1, j-1))

	parser.call(diffs, action_key)

func validate_move_diff(diffs : Array[Diff], action_key : int, can_gobble := false) -> Dictionary:
	var old : Diff
	var new : Diff
	if len(diffs) != 2:
		on_invalid_action(action_key, 'Invalid number of move diffs (%s)' % len(diffs))
		return {valid = false}

	for diff in diffs:
		if diff.new == '0':
			old = diff

		if diff.old == '0' or (can_gobble and diff.old == 'x'):
			new = diff

	if old == null or new == null:
		on_invalid_action(action_key, "Didn't find old or new %s %s" % [old, new])
		return {valid = false}

	return {old = old, new = new, valid = true}

func parse_invisible(diffs: Array[Diff], action_key : int):
	if len(diffs) > 0:
		on_invalid_action(action_key, "Can't do additional actions when turning invisible")
		return

	effects |= INVISIBLE
	avatar.visible = false
	emit_signal('finished')

func parse_swap(diffs : Array[Diff], action_key : int):
	if len(diffs) != 2:
		on_invalid_action(action_key, "Can't swap %s objects" % len(diffs))
		return

	var a = game.get_at(diffs[0].loc)
	var b = game.get_at(diffs[1].loc)

	if a == null or b == null:
		on_invalid_action(action_key, 'Invalid swap %s %s' % [a, b])
		return

	a.move_to(diffs[1].loc, a == self)
	b.move_to(diffs[0].loc, b == self)


func parse_target(_diffs : Array[Diff], _action_key : int):
	pass

func parse_unmine(diffs : Array[Diff], action_key : int):
	if len(diffs) != 1:
		on_invalid_action(action_key, 'Can not unmine %s mines' % len(diffs))
		return

	var diff := diffs[0]
	if not (diff.old == 'x' and diff.new == '0'):
		on_invalid_action(action_key, 'Can no unmine %s -> %s' % [diff.old, diff.new])

	remove_mine_at(diff.loc)

func parse_charge(diffs : Array[Diff], action_key : int):
	print('parse charge ', action_key)
	var mines : Array[Diff] = []
	var moves : Array[Diff] = []

	for diff in diffs:
		if (is_user(diff.old) and diff.new == '0') or (not is_user(diff.old) and is_user(diff.new)):
			moves.append(diff)
		elif (diff.old == 'x' and diff.new == '0'):
			mines.append(diff)
		else:
			on_invalid_action(action_key, '%s is neither a move no a mine' % diff)
			return

	var move_dict := validate_move_diff(moves, action_key, true)
	if not move_dict.valid:

		return

	var old = move_dict.old
	var new = move_dict.new

	if not is_valid_charge(old, new, mines, action_key):
		on_invalid_action(action_key, 'Invalid charge')
		return

	for mine in mines:
		remove_mine_at(mine.loc)
	if new.old == 'x':
		remove_mine_at(new.loc)

	move_to(new.loc)

func is_user(s : String):
	return s != 'x' and s != '0'

func is_valid_charge(_old, _new, _mines, _action_key):
	# Check to make sure that all the mines live on the ray from old to new
	# and that old and new are the correct ray
	return true

func parse_move(diffs : Array[Diff], action_key : int):
	var dict := validate_move_diff(diffs, action_key)
	if not dict.valid:
		return

	var old : Diff = dict.old
	var new : Diff = dict.new

	var step := old.loc - new.loc
	if maxi(abs(step.x), abs(step.y)) != 1:
		on_invalid_action(action_key, 'Bad step: (%s)->(%s)' % [old.loc, new.loc])
		return

	move_to(new.loc)

func parse_attack(diffs : Array[Diff], _action_key : int):
	# I can't be bothered to validate this right now. Worry about validation later.
#	var dict : Dictionary = Global.explode_key(action_key)
#	var indices : Array[int] = []
#	var rel_locs : Array[Vector2i] = []
#	for index in dict.nibbles:
#		if index != 0:
#			indices.append(index)
#			rel_locs.append()
#
#	print(Global.explode_key(action_key))
	for diff in diffs:
		if diff.old == '0' and diff.new == 'x':
			place_at(diff.loc, false)

func parse_defend(diffs : Array[Diff], _action_key : int):
	# I can't be bothered to validate this right now. Worry about validation later.
	for diff in diffs:
		if diff.old == 'x' and diff.new == '0':
			remove_mine_at(diff.loc, false)

func parse_teleport(diffs : Array[Diff], action_key : int):
	var dict := validate_move_diff(diffs, action_key)
	if not dict.valid:
		return

	var teleporter_id = dict.new.new
	var mover : Player
	for player in game.players:
		if player.id == teleporter_id:
			mover = player

	mover.move_to(dict.new.loc, false)
	await mover.finished
	emit_signal('finished')

func parse_mine(diffs : Array[Diff], action_key : int):
	if len(diffs) != 1:
		on_invalid_action(action_key, 'Incorrect number of changes for mine %s ' % len(diffs))
		return

	var spot = diffs[0]
	if spot.old == '0' and spot.new == 'x':
		place_at(spot.loc)
	else:
		on_invalid_action(action_key, 'Illegal mine %s->%s' % [spot.old, spot.new])

func parse_invalid(args : Array[Diff], action_key : int):
	var explode = Global.explode_key(action_key)
	if explode.schema == 'attack':
		parse_attack(args, action_key)
	elif explode.schema == 'defend':
		parse_defend(args, action_key)
	else:
		print(explode)
		on_invalid_action(action_key, 'Invalid args %s' % [args])



func on_invalid_action(action_key : int, note : String):
	push_warning('invalid: %s: %s' % [action_key, note])
	await avatar.get_tree().process_frame
	await avatar.get_tree().process_frame
	emit_signal('finished')

func send_action(_send : bool):
	pass
