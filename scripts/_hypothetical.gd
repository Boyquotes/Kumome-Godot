extends Node
class_name Hypothetical

# This class is used by the AI to make decsions. It doesn't make any decisions by itself, rather
# it simply assess a hypthetical game board and scroes it based on how good it is for a given
# team.

var dimensions := Vector2i.ZERO
var squares := []

# Generate data based on an existing game
func from_game(g : Game):
	resize(g.dimensions)
	for player in g.players:
		set_square(player.location, [player.id, player.team])

	for mine in g.mines:
		set_square(mine.location, 'x')

# Create a copy of oneself
func copy(deep := false) -> Hypothetical:
	var hyp = Hypothetical.new()
	hyp.dimensions = dimensions
	hyp.squares = squares.duplicate(deep)
	return hyp

func is_valid_square(at : Vector2i) -> bool:
	return at.x >= 0 and at.x < dimensions.x and at.y >= 0 and at.y < dimensions.y

func get_square(at : Vector2i):
	if is_valid_square(at):
		return squares[at.x + at.y*dimensions.x]
	else:
		return 'w'

func set_square(at : Vector2i, value):
	if is_valid_square(at):
		squares[at.x + at.y * dimensions.x] = value

# Gets a count for how many squares surrounding "at" are either mines or players.
func get_square_clutter(at : Vector2i) -> int:
	var rv := 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i != 0 or j != 0:
				if get_square(at + Vector2i(i, j)) != null:
					rv += 1
	return rv

# Gives a score based on how cluttered a given team is vs how clutted an opposing
# team is. The args offence and defence allow you to adjust how much the scoring
# cares about cluttering opposing team or avoiding clutter for the given team respectively.
func score_for_team(team : int, offence := 3, defence := 2) -> int:
	var rv := 0
	for col in dimensions.x:
		for row in dimensions.y:
			var loc = Vector2i(col, row)
			var sq = get_square(loc)
			if sq is Array:
				var sq_team : int = sq[1]
				var sq_clutter = get_square_clutter(loc)
				if sq_team == team:
					rv -= defence * sq_clutter
				else:
					rv += offence * sq_clutter
	return rv

func score_for_player(player : Player, offence := 3, defence := 3) -> int:
	return score_for_team(player.team, offence, defence)

# Returns a copy of this Hypothetical with the object at "from" moved to "to."
#It does NOT do any checking to make sure either "from" or "to" is empty/full.
func what_if_move(from : Vector2i, to : Vector2i) -> Hypothetical:
	var hyp = copy()
	var mover = hyp.get_square(from)
	hyp.set_square(from, null)
	hyp.set_square(to, mover)
	return hyp

# Returns a copy of this Hypothetical with the "at" replaced with a mine.
# It does NOT do any check whether "at" is first occupied or not
func what_if_mine(at : Vector2i) -> Hypothetical:
	var hyp = copy()
	hyp.set_square(at, 'x')
	return hyp

func resize(dim : Vector2i):
	squares.resize(dim.x * dim.y)
	dimensions = dim


# Methods usefult for debuggin

func _to_string() -> String:
	return get_string(0)

func get_teams_string() -> String:
	return get_string(1)

func get_string(index : int) -> String:
	var rv := ''
	var i := 0
	for sq in squares:
		if sq == null:
			rv += '.'
		elif sq is String:
			rv += sq
		elif sq is Array:
			rv += str(sq[index])
		i += 1
		if i >= dimensions.x:
			rv += '|'
			i = 0
	return rv
