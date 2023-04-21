extends Node
class_name Game

signal added_mine
signal game_over
signal phase_change
signal turn_started
signal commited_to_action

enum PHASES {START, MOVE, PLACE, NO_PLACE, NONE}

var players : Array[Player] = []
var mines : Array[Mine] = []
var active_player : Player
var active_team := -1
var turn := 0
var phase := PHASES.START
var board : GameBoard
var dimensions : Vector2i
var message : String : get = get_message
var verbose := false

# Perhaps should convert these to a Phase classes
var phase_tree := {
	PHASES.START : {
		PHASES.MOVE : null,
	},
	PHASES.MOVE : {
		PHASES.NONE : game_is_over,
		PHASES.NO_PLACE: is_active_player_stuck,
		PHASES.PLACE : null
	},
	PHASES.PLACE : {
		PHASES.MOVE : null
	},
	PHASES.NO_PLACE : {
		PHASES.MOVE : null
	},
	PHASES.NONE : {
		PHASES.NONE : null
	}
}

var phase_callbacks := {
	PHASES.START : phase_start,
	PHASES.MOVE : phase_move,
	PHASES.PLACE : phase_place,
	PHASES.NO_PLACE: phase_none,
	PHASES.NONE : phase_none
}

func _init(_board : GameBoard, dims := Vector2i.ZERO):
	write("Let's play a game")
	connect('tree_exiting', func(): write('Goodbye Cruel World!'))
	board = _board

	if dims == Vector2i.ZERO:
		dimensions = board.dimensions
	else:
		dimensions = dims
		board.dimensions = dims


func start():
	phase = PHASES.START
	run()
	#next()

func phase_start():
	pass

func phase_move():
	write('\t-> move')
	get_next_active_player()
	active_player.move()
	write('\t%s is %sstuck' % [active_player, '' if active_player.stuck else 'not '])

func phase_card():
	write('\t-> card')
	active_player.play_card()
	write('\t%s is %sstuck' % [active_player, '' if active_player.stuck else 'not '])

func phase_place():
	write('\t-> place')
	active_player.place()

func phase_end():
	write('\t-> END')
	emit_signal('game_over')

func phase_none():
	write('\t-> No action')

func run():
	while true:
		get_next_active_player()
		emit_signal('turn_started', active_player)
		if game_is_over():
			break
		if is_active_player_stuck():
			continue

		phase_card()
		await active_player.card_finished


	emit_signal('game_over')

func run_old():
	while true:
		write('Go to phase after', pretty(phase), active_player)
		var links = phase_tree[phase]
		var callback : Callable
		var patient := false

		for next_phase in links:
			if links[next_phase] == null:
				phase = next_phase
				callback = phase_callbacks[next_phase]
				patient = true
			elif links[next_phase].call():
				phase = next_phase
				callback = phase_none
				break

		write('\t->', pretty(phase), 'callback', patient)
		callback.call()
		write('\t->', pretty(phase), active_player)
		emit_signal('phase_change')

		if phase == PHASES.NONE:
			break
		elif patient:
			write('\t-> waiting...')
			await active_player.finished
			write('\t-> ...finished!')

	emit_signal('game_over')

func pretty(ph : PHASES):
	return PHASES.keys()[ph]

func game_is_over() -> bool:
	write('\t(game is %sover)' % ['' if len(get_active_teams()) < 2 else 'not '])

	return len(get_active_teams()) < 2

func get_winning_team() -> int:
	var active_teams := get_active_teams()
	if len(active_teams) == 1:
		return active_teams[0]
	else:
		return -1

func get_active_teams() -> Array[int]:
	var active_teams : Array[int] = []

	for player in players:
		if not player.stuck and not player.team in active_teams:
			active_teams.append(player.team)

	return active_teams

func get_next_active_player() -> void:
	var teams := get_active_teams()
	if active_team == -1:
		active_team = minimum(teams)
		for player in players:
			if player.team == active_team:
				active_player = player
				break
		return

	var team_index = teams.find(active_player.team)
	team_index = wrapi(team_index + 1, 0, len(teams))
	active_team = teams[team_index]

	var best_player = null
	for player in players:
		if (
			player.team == active_team and
			not player.stuck and
			(best_player == null or player.turns < best_player.turns)
		):
			best_player = player

	active_player = best_player

func minimum(list : Array):
	var lowest = list[0]
	for x in list:
		if x < lowest:
			lowest = x
	return lowest

#	var player_index = players.find(active_player)
#	while true:
#		player_index += 1
#		if player_index >= len(players):
#			player_index = 0
#
#		var next_player = players[player_index]
#		if active_player == next_player:
#			return
#		elif active_player.team == next_player.team:
#			continue
#		elif next_player.stuck:
#			continue
#		else:
#			active_player = next_player
#			return
#	return

func is_finished() -> bool:
	var player_index = players.find(active_player)
	while true:
		player_index += 1
		if player_index >= len(players):
			player_index = 0

		var next_player = players[player_index]
		if active_player == next_player:
			return true
		elif active_player.team == next_player.team:
			continue
		elif next_player.stuck:
			continue
		else:
			return false

	return false

func is_active_player_stuck() -> bool:
	write('\t(check stuck %s)' % active_player)
	if active_player.stuck:
		write('\t\tNO PLACE FOR ', active_player)
	return active_player.stuck

func add_player(p : Player):
	p.id = len(players)
	players.append(p)
	p.game = self
	p.avatar.size = board.square_size
	p.connect('commited_to_action', emit_signal.bind('commited_to_action'))

func add_mine_at(at : Vector2i, color := Color.BLACK) -> Mine:
	return add_any_mine_at(Mine.new(), at, color)

func add_instant_mine_at(at : Vector2i, color := Color.BLACK) -> Mine:
	return add_any_mine_at(MineInstant.new(), at, color)

func remove_mine_at(at : Vector2i) -> Array[Mine]:
	print('look for mine at ', at)
	var rv : Array[Mine] = []
	for mine in mines:
		if mine.location == at:
			print('remove mine at ', at)
			mine.destroy()
			rv.append(mine)
	for mine in rv:
		mines.erase(mine)
	return rv

func add_any_mine_at(mine : Mine, at : Vector2i, color : Color) -> Mine:
	mine.location = at
	mine.avatar.modulate = color
	mine.avatar.position = board.to_position(at)
	mine.avatar.size = board.square_size
	mines.append(mine)
	emit_signal('added_mine', mine)
	return mine

func is_open(at : Vector2i):
	for player in players:
		if player.location == at:
			return false

	for mine in mines:
		if mine.location == at:
			return false

	return true

func get_opens() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	for i in dimensions.x:
		for j in dimensions.y:
			rv.append(Vector2i(i, j))

	for player in players:
		rv.erase(player.location)

	for mine in mines:
		rv.erase(mine.location)

	return rv

func get_mine_spots() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	for mine in mines:
		rv.append(mine.location)

	return rv

func write(a, b = '', c = '', d = ''):
	if verbose:
		prints(a, b, c, d)

func get_message():
	return {
		PHASES.START : 'Move',
		PHASES.MOVE : 'Move',
		PHASES.PLACE : 'Place Mine',
		PHASES.NO_PLACE: 'No Place',
		PHASES.NONE: 'Game Over!!'
	}[phase]

func get_hypothetical() -> Hypothetical:
	var hy := Hypothetical.new()
	hy.from_game(self)
	return hy
