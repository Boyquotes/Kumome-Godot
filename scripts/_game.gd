extends Node
class_name Game

signal added_mine
signal game_over
signal phase_change
signal turn_started
signal commited_to_action

var players : Array[Player] = []
var mines : Array[Mine] = []
var active_player : Player
var active_team := -1
var turn := 0
var board : GameBoard
var dimensions : Vector2i
var verbose : bool = false
var is_remote := false
var id : String

func _init(_board : GameBoard, dims := Vector2i.ZERO, _id := ''):
	board = _board
	id = _id

	if dims == Vector2i.ZERO:
		dimensions = board.dimensions
	else:
		dimensions = dims
		board.dimensions = dims

func start():
	run()

# This is the heart of the game loop, as outlined in the first page of the design doc
func run():
	while true:
		get_next_active_player()

		# This signal tells UI elements to update
		emit_signal('turn_started', active_player)

		if game_is_over():
			break
		if is_active_player_stuck():
			continue

		# Hand control over to active_player and then wait until it emits the
		# signal "card_finished"
		active_player.play_card()
		await active_player.card_finished


	emit_signal('game_over')

func game_is_over() -> bool:
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

func find_next_active_player() -> Player:
	var teams := get_active_teams()
	var a_team := active_team
	if a_team == -1:
		a_team = minimum(teams)
		for player in players:
			if player.team == a_team:
				return player

	var team_index = teams.find(active_player.team)
	team_index = wrapi(team_index + 1, 0, len(teams))
	a_team = teams[team_index]

	var best_player = null
	for player in players:
		if (
			player.team == a_team and
			not player.stuck and
			(best_player == null or player.turns < best_player.turns)
		):
			best_player = player

	return best_player

# I think this method is kinda sloppy and potentially buggy.
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

func is_active_player_stuck() -> bool:
	return active_player.stuck

func add_player(p : Player):
	#p.id = str(len(players)) if id == '' else id
	players.append(p)
	p.game = self
	p.avatar.size = board.square_size
	p.connect('commited_to_action', emit_signal.bind('commited_to_action'))
	p.connect('sent', send_action)
	if p is PlayerRemote:
		is_remote = true


func send_action(key : int):
	if not is_remote: return

	WS.send_board_update(
		key,
		active_player.card.key,
		active_player.id,
		active_player.id if active_player.is_active else find_next_active_player().id,
		id,
		export_board()
	)

func export_board() -> Array:
	var rv = [null]
	for i in range(dimensions.y):
		rv.append([null])
		for j in range(dimensions.x):
			rv[i+1].append('0')

	for player in players:
		rv[player.location.x + 1][player.location.y + 1] = player.id

	for mine in mines:
		rv[mine.location.x + 1][mine.location.y + 1] = 'x'

	return rv

func add_mine_at(at : Vector2i, color := Color.BLACK) -> Mine:
	return add_any_mine_at(Mine.new(self), at, color)

func add_instant_mine_at(at : Vector2i, color := Color.BLACK) -> Mine:
	return add_any_mine_at(MineInstant.new(), at, color)


# If there is no mine at the requested location, return an empty array
# If there is a mine at the requested location, return an array with the mine in it
func remove_mine_at(at : Vector2i) -> Array[Mine]:
	var rv : Array[Mine] = []
	for mine in mines:
		if mine.location == at:
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

# Is the requested point cluttered with mines/other players?
func is_open(at : Vector2i) -> bool:

	for player in players:
		if player.location == at:
			return false

	for mine in mines:
		if mine.location == at:
			return false

	return is_valid_spot(at)

func is_valid_spot(at : Vector2i) -> bool:
	return at.x >= 0 and at.y >= 0 and at.x < dimensions.x and at.y < dimensions.y

# Get all uncluttered points
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

func get_ray(point : Vector2i, dir : Vector2i, walls : Array[Vector2i] = get_player_spots()) -> Array[Vector2i]:
	var rv : Array[Vector2i] = []

	while is_valid_spot(point) and not point in walls:
		rv.append(point)
		point += dir

	return rv

func get_edge_spots() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []

	for i in dimensions.x:
		var a = Vector2i(i, 0)
		var b = Vector2i(i, dimensions.y - 1)
		if is_open(a) and not a in rv:
			rv.append(a)
		if is_open(b) and not b in rv:
			rv.append(b)

	for j in dimensions.y:
		var a = Vector2i(0, j)
		var b = Vector2i(dimensions.x - 1, j)
		if is_open(a) and not a in rv:
			rv.append(a)
		if is_open(b) and not b in rv:
			rv.append(b)

	return rv

func get_spots_adjacent_to_players(list : Array[Player]) -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	var opens = get_opens()
	for m in opens:
		for p in list:
			if abs(m.x - p.location.x) <= 1 and abs(m.y - p.location.y) <= 1 and not m in rv:
				rv.append(m)

	return rv

func get_at(loc : Vector2i):
	for p in players:
		if p.location == loc:
			return p
	for m in mines:
		if m.location == loc:
			return m
	return null

# Get all points with a mine on them
func get_mine_spots() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	for mine in mines:
		rv.append(mine.location)

	return rv

func get_player_spots() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	for player in players:
		rv.append(player.location)

	return rv

func get_hypothetical() -> Hypothetical:
	var hy := Hypothetical.new()
	hy.from_game(self)
	return hy
