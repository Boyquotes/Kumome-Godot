extends Node

const board_4p := '........|........|........|...02...|...31...|........|........|........'
const board_8p := '........|........|...56...|..2..0..|..1..3..|...74...|........|........'

enum AVATARS {
	RANDOM = -1, RED = 0, YELLOW = 1, BLACK = 2, WHITE = 3, BOT = 4,
	BEAR = 5, CHICKEN = 6, ELEPHANT = 7, OWL = 8, RHINO = 9, SNAKE = 10, MONKEY = 11, WALRUS = 12
}

var settings := {
	playing_with_cards = false,
	special_cards_per_game = 2
}

func adjust_setting(st, val):
	assert(st in settings)
	settings[st] = val

func parse_code(level_code : String, parse_constructor_code : Dictionary) -> Dictionary:

	var parse_header := true
	var key := []
	var map : Array[Dictionary] = []
	var size := Vector2i.ZERO
	for line in level_code.split('\n'):
		if parse_header:
			if line.begins_with('-'):
				parse_header = false
			else:
				var split = line.split(' ')
				if len(split) != 3:
					return {'valid' = false}
				key.append([
					parse_constructor_code.get(split[0]),
					int(split[1]),
					int(split[2])
				])
		elif len(line):
			for i in len(line):
				var c = line[i]
				if c.is_valid_int():
					var data = key[c.to_int()]
					map.append({
						player = true,
						constructor = data[0],
						color = data[1],
						team = data[2],
						loc = Vector2i(i, size.y)
					})
				elif c == 'x':
					map.append({
						player = false,
						loc = Vector2i(i, size.y)
					})
			size.y += 1
			size.x = max(size.x, len(line))
	return {size = size, map = map, valid = true}

func generate_2p_level(p1 : String, p2 : String, size : int, starting_mines : bool) -> String:
	var half := int(size/2)
	var rv := ""
	rv += '%s 0 0\n' % p1
	rv += '%s 1 1\n' % p2
	rv += '-'
	for i in size:
		var line := '\n'
		for j in size:
			if i == half and j == half:
				line += '1'
			elif i == half - 1 and j == half - 1:
				line += '0'
			elif i == half and j == half - 1 and starting_mines:
				line += 'x'
			elif i == half - 1 and j == half and starting_mines:
				line += 'x'
			else:
				line += '.'
		rv += line

	return rv

## players = Array[B/L : String, avatar_id : AVATARS, team : int]
func generate_standard_board(players : Array) -> String:
	var rv := ''
	var board_size : int
	var board : String

	if len(players) > 4:
		board_size = 8
		board = board_8p
	else:
		board_size = 4
		board = board_4p

	var avatars := [
		AVATARS.BEAR, AVATARS.SNAKE, AVATARS.CHICKEN, AVATARS.ELEPHANT,
		AVATARS.OWL, AVATARS.RHINO,  AVATARS.MONKEY, AVATARS.WALRUS
	]

	for  player in players:
		avatars.erase(player[1])

	for player in players:
		if player[1] == AVATARS.RANDOM:
			player[1] = avatars.pop_front()
		rv += '%s %s %s\n' % player

	rv += '-\n'

	for i in board_size:
		if i >= len(players):
			board = board.replace(str(i), 'x')

	rv += board.replace('|', '\n')

	return rv

