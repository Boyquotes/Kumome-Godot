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
var verbose := false

func _init(_board : GameBoard, dims := Vector2i.ZERO):
	board = _board

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
	p.id = len(players)
	players.append(p)
	p.game = self
	p.avatar.size = board.square_size
	p.connect('commited_to_action', emit_signal.bind('commited_to_action'))

func add_mine_at(at : Vector2i, color := Color.BLACK) -> Mine:
	return add_any_mine_at(Mine.new(), at, color)

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
func is_open(at : Vector2i):
	for player in players:
		if player.location == at:
			return false

	for mine in mines:
		if mine.location == at:
			return false

	return true

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

# Get all points with a mine on them
func get_mine_spots() -> Array[Vector2i]:
	var rv : Array[Vector2i] = []
	for mine in mines:
		rv.append(mine.location)

	return rv

func get_hypothetical() -> Hypothetical:
	var hy := Hypothetical.new()
	hy.from_game(self)
	return hy
