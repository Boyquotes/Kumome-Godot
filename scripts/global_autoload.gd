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

var action_defend_rel_dirs : Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0), Vector2i(0,  0), Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
]

var actions : Dictionary = {}
var modifiers : Dictionary = {}
var card_arts : Dictionary = {}

var attacks := []
var defends := []

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

	for ad in get_data('AttacksAndDefends'):
		if ad.attack:
			attacks.append(get_attack_defend_key(true, ad))
		if ad.defend:
			defends.append(get_attack_defend_key(false, ad))

#	var keys = []
#	for i in range(23):
#		keys.append(get_card(i).key)
#
#	print(keys):

# 0 1 2
# 3 4 5
# 6 7 8

func get_attack_defend_key(attack : bool, dict : Dictionary) -> int:
	var locs : Array[int] = []
	locs.append(int(dict.primary))
	var n = len(locs)

	while len(locs) < 12:
		locs.append(int(dict.get('additional_%s' % n, 0)))
		n += 1

	var cost : int = dict.cost
	var key := 0
	key = shift_key(key, 2)
	key = shift_key(key, 10 if attack else 13)
	key = shift_key(key, cost)

	for loc in locs:
		key = shift_key(key, loc)

	return key


func generate_attacks(count):
	var list : Array[Array] = [empty()]
	for _i in count:
		list = next_gen(list)

	list = filter(list)
	for grid in list:
		pos_print(grid)
	print(len(list))

func pos_print(grid : Array):
	var a := []
	for n in len(grid):
		if grid[n]:
			a.append(n + 1)
	print(a)

func pretty_print(grid : Array):
	var s = ''
	var n := 0
	for b in grid:
		n += 1
		s += ('x' if b else '.')
		if n % 3 == 0:
			s += '\n'

	print(s)

func empty() -> Array:
	var rv : Array = []
	rv.resize(9)
	rv.fill(false)
	return rv

func next_gen(list : Array[Array]) -> Array[Array]:
	var rv : Array[Array] = []
	for grid in list:
		for n in 9:
			if grid[n] == false:
				var next = grid.duplicate()
				next[n] = true
				rv.append(next)

	return rv

func shift_up(line : Array) -> Array:
	return line.slice(3) + line.slice(0, 3)

func shift_left(line : Array) -> Array:
	return [line[1], line[2], line[0], line[4], line[5], line[3], line[7], line[8], line[6]]

func to_canonical(grid : Array) -> Array:
	while not (grid[0] or grid[1] or grid[2]):
		grid = shift_up(grid)
	while not (grid[0] or grid[3] or grid[6]):
		grid = shift_left(grid)
	return grid


func filter(list : Array[Array]) -> Array[Array]:
	var rv : Array[Array] = []
	for grid in list:
		if not to_canonical(grid) in rv:
			rv.append(to_canonical(grid))
	return rv

func shift_key(key : int, value : int, steps := 1):
	for _i in steps:
		key *= 16
	key += value
	return key

func get_card(n : int) -> Card:
	return Card.new(get_data('Cards')[n])

func get_attack(n : int) -> Card:
	return CardAttackDefend.new(attacks[n])

func get_defend(n : int) -> Card:
	return CardAttackDefend.new(defends[n])

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

func get_pretty_key(key) -> String:
	var s = String.num_int64(key, 16)
	return '%s|%s|%s|%s|%s|%s' % [s[0], s[1], s[2], s.substr(3,4), s.substr(7,4), s.substr(11,4)]

func explode_key(key) -> Dictionary:
	var rv := {'nibbles': [], 'blocks': []}
	for n in 12:
		rv['d%s' % (11 - n)] = key % 16
		rv['nibbles'].push_front(key % 16)
		key /= 16

	rv['c'] = key % 16
	key /= 16

	rv['s'] = key % 16
	key /= 16

	rv['v'] = key % 16

	for i in 3:
		rv['blocks'].append(0)
		for j in 4:
			rv['blocks'][i] += powi(16, 3-j)*rv['d%s' % (j + 4*i)]

	rv['pretty'] = '%s|%s|%s|%s|%s|%s' % [
		String.num_int64(rv['v'], 16),
		String.num_int64(rv['s'], 16),
		String.num_int64(rv['c'], 16),
		pad(String.num_int64(rv['blocks'][0], 16), 4),
		pad(String.num_int64(rv['blocks'][1], 16), 4),
		pad(String.num_int64(rv['blocks'][2], 16), 4)
	]

	if rv['s'] == 1:
		rv['schema'] = 'action'
	elif rv['s'] == 10:
		rv['schema'] = 'attack'
	elif rv['s'] == 13:
		rv['schema'] = 'defend'
	elif rv['s'] == 14:
		rv['schema'] = 'error'
	else:
		rv['schema'] = 'unknown'

	return rv

func powi(base : int, ex : int) -> int:
	if ex <= 0:
		return 1
	else:
		return base * powi(base, ex - 1)

func pad(s : String, amnt : int) -> String:
	while len(s) < amnt:
		s = '0' + s
	return s

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

