extends Node

# This is an autoload, other languages call it a "singleton" Any method or value in this script
# can be accessed via the global variable "Global" For example, Global.board_4p or Global.adjust_settings()

const base_url := 'localhost:3001'
#const base_url := '159.223.106.122:3001'
const url := 'http://' + base_url

const board_4p := '........|........|........|...02...|...31...|........|........|........'
const board_8p := '........|........|...56...|..2..0..|..1..3..|...74...|........|........'

const USER_PATH = 'user://active_user.data'

enum AVATARS {
	RANDOM = -1, RED = 0, YELLOW = 1, BLACK = 2, WHITE = 3, BOT = 4,
	BEAR = 5, CHICKEN = 6, ELEPHANT = 7, OWL = 8, RHINO = 9, SNAKE = 10, MONKEY = 11, WALRUS = 12
}

var active_user := {
	logged_in = false
}

var settings := {
	playing_with_cards = true,
	special_cards_per_game = 2
}

var actions : Dictionary = {}
var modifiers : Dictionary = {}
var card_arts : Dictionary = {}

@onready var data : Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/data.json"))

func _ready():
	if FileAccess.file_exists(USER_PATH):
		var file = FileAccess.open(USER_PATH, FileAccess.READ)
		active_user = file.get_var()

	for mod in get_data('Modifiers'):
		modifiers[mod.name] = int(mod.key)

	for act in get_data('Actions'):
		actions[act.name] = int(act.key)

	var card_art_path := "res://imgs/card_art/"
	for img in DirAccess.get_files_at(card_art_path):
		if img.get_extension() == 'png':
			var path := card_art_path.path_join(img)
			card_arts[FileAccess.get_md5(path)] = load(path)


#func generate_all_cards():
#	var actions = {
#		'move': ['_'],
#		'mine': ['_'],
#		'teleport': ['_', 'ALLY', 'ENEMY', 'EDGE', 'RANDOM'],
#		'unmine': ['_', 'EDGE', 'RANDOM', 'OTHER', 'SELF'],
#		'charge': ['N', 'S', 'E', 'W', 'SE', 'NE', 'SW', 'NW', 'RANDOM'],
#		'target': ['SELF', 'ALLY', 'OTHER', 'RANDOM', 'MINE']
#	}
#
#	var i := 0
#	for a1 in actions:
#		for a2 in actions:
#			for m1 in actions[a1]:
#				for m2 in actions[a2]:
#					if (
#						(a1 == 'teleport') or
#						(a1 == 'target' and a2 != 'teleport') or
#						(a1 != 'target' and a2 == 'teleport')
#					):
#						continue
#					i += 1
#					prints(i, a1, m1, a2, m2)

func get_card(n : int) -> Card:
	return Card.new(get_data('Cards')[n])

func get_action_key(act : String, mod : String) -> int:
	if not act in actions or not mod in modifiers:
		push_warning('Invaild (action, modifier): (%sv %s)' % [act, mod])
		return -1
	return 256 * modifiers[mod] + actions[act]

func get_data(sheet_name : String) -> Array[Dictionary]:
	var rv : Array[Dictionary] = []
	for sheet in data.sheets:
		if sheet.name == sheet_name:
			for line in sheet.lines:
				if line.get('active', true):
					rv.append(line)
			break

	return rv

func adjust_setting(st, val):
	assert(st in settings)
	settings[st] = val

func log_in(user_data : Dictionary):
	active_user.logged_in = true
	active_user.token = user_data.get('token', '')
	var user = user_data.get('user', {})
	active_user.id = user.get('_id', '')
	active_user.email = user.get('email', '')
	active_user.username = user.get('username', '')

	save_user()

func log_out():
	active_user = {logged_in = false}
	save_user()

func save_user():
	var file = FileAccess.open(USER_PATH, FileAccess.WRITE)
	file.store_var(active_user)

func create_remote_game(board : Array, id : String) -> String:
	var players := []
	var header := ''
	var body := ''
	for i in range(1, len(board)):
		for j in range(1, len(board[i])):
			var square = board[i][j]
			if square == '0':
				body += '.'
			elif square == 'x':
				body += 'x'
			else:
				body += str(len(players))
				players.append([square, square == active_user.id, len(players)])
		body += '\n'

	for player in players:
		header += '%s %s %s %s\n' % [
			'L' if player[1] else 'R',
			player[2],
			player[2],
			player[0]
		]
	return '#%s\n%s\n-\n%s' % [id, header, body]

# Parses a given level_code and returns a dictionary with all the relevant data.
# The details of the level_code spec can be found in "res://scripts/notes.gd". The parse_consturctoe_code dictionary
# shoud be of the form: {
#	'L' : method_that_processes_local_player(id : int, team : int, at : Vector2i),
#	'B' : method_that_processes_ai_player(id : int, team : int, at : Vector2i),
#	'R' : method_that_processes_remote_player(id : int, team : int, at : Vector2i),
#	'I' : method_that_processes_ai_instant_player(id : int, team : int, at : Vector2i)
# }, see "res://scripts/play.gd" for an example
# The returned dictionary will be of the form: {
#	size : Vector2i (size of the game board),
#	map : Array (list of mine and player data),
#	valid : bool (a flag indicating whether the level_code was legit or not)
#}
func parse_code(level_code : String, parse_constructor_code : Dictionary) -> Dictionary:

	var parse_header := true
	var key := []
	var map : Array[Dictionary] = []
	var size := Vector2i.ZERO
	var count := -1
	var id := ''
	for line in level_code.split('\n'):
		count += 1
		if parse_header:
			if line.begins_with('#'):
				id = line.substr(1).strip_edges()
			elif line.begins_with('-'):
				parse_header = false
			else:
				var split = line.strip_edges().split(' ')
				if len(line) == 0:
					continue
				elif len(split) == 3:
					split.append(str(count))
				elif len(split) != 4:
					push_warning('bad header line (%s)(%s)' % [split, line])
					return {'valid' = false}
				key.append([
					parse_constructor_code.get(split[0]),
					int(split[1]),
					int(split[2]),
					split[3]
				])
		elif len(line):
			for i in len(line):
				var c = line[i]
				if c.is_valid_int():
					var dict = key[c.to_int()]
					map.append({
						player = true,
						constructor = dict[0],
						color = dict[1],
						team = dict[2],
						loc = Vector2i(i, size.y),
						id = dict[3]
					})
				elif c == 'x':
					map.append({
						player = false,
						loc = Vector2i(i, size.y)
					})
			size.y += 1
			size.x = max(size.x, len(line))
	return {size = size, map = map, valid = true, id = id}

# Useful for making a quick level_code for debugging purposes
func generate_2p_level(p1 : String, p2 : String, size : int, starting_mines : bool) -> String:
	var half := int(size/2.0)
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

# Generates a standard starting board based on the rules outlined in the Print and Play pages 2 and 3
# the array players must be an array of arrays. Each sub-array is of the form:
# [B/L/R/I : String, avatar_id : AVATARS, team : int]
# Where B, L, R, I indicate AI, Local, Remote, and Instant respectivly
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

