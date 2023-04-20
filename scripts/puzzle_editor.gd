extends SwapScene

signal played

var active_id : String
var avatars := {}
var level_code : String : get = generate_code, set = set_code
var _code : String

func _ready():
	for butt in $buttons.get_children():
		butt.connect('touched', change_icon)

	$size_down.connect('touched', resize.bind(-1))
	$size_up.connect('touched', resize.bind(1))

	emit_signal("changed_quit_to", preload("res://scenes/puzzle_editor.tscn"))

	change_icon('player')

	setup()

func setup():
	var data = Global.parse_code(_code, {})
	if data.valid:
		$board.dimensions = data.size
		add_touch_spots()
		add_avatars()

		for piece in data.map:
			var av = avatars[piece.loc]
			if piece.player and piece.team == 0:
				av.id = 'player'
			elif piece.player and piece.team == 1:
				av.id = 'bot'
			elif not piece.player:
				av.id = 'mine'

	else:
		add_touch_spots()
		add_avatars()
		avatars[Vector2i.ZERO].id = 'player'

	_code = ''




func resize(_id, dir):
	var s = $board.dimensions.x
	s = clampi(s + dir, 4, 10)
	$board.dimensions = Vector2i(s, s)
	$Label.text = str(s)
	setup()

func change_icon(id : String):
	active_id = id

func on_touch_spot_touched(location : Vector2i):
	var avatar = avatars[location]

	if active_id == 'player':
		for av in $avatars.get_children():
			if av.id == 'player' and av != avatar:
				av.id = 'none'


	if avatar.id == active_id:
		avatar.id = 'none'
	else:
		avatar.id = active_id



func add_touch_spots():
	for spot in $touch_spots.get_children():
		spot.queue_free()

	var board := $board
	var potentials := []

	for i in $board.dimensions.x:
		for j in $board.dimensions.y:
			potentials.append(Vector2i(i, j))

	for pot_spot in potentials:
		var touch_spot = preload("res://scenes/touch_spot.tscn").instantiate()
		touch_spot.location = pot_spot
		touch_spot.size = board.square_size
		touch_spot.modulate = Color(0, 0, 0, 0)
		touch_spot.position = board.to_position(pot_spot)
		$touch_spots.add_child(touch_spot)

		touch_spot.connect('touched', on_touch_spot_touched)


func add_avatars():
	for av in $avatars.get_children():
		av.queue_free()

	for i in $board.dimensions.x:
		for j in $board.dimensions.y:
			var av = preload("res://scenes/puzzle_avatar.tscn").instantiate()
			av.position = $board.to_position(Vector2i(i, j))
			av.size = $board.square_size
			avatars[Vector2i(i, j)] = av
			$avatars.add_child(av)


func generate_code() -> String:
	var rv := ''
	rv += 'L 1 0\n'
	rv += 'B 4 1\n'
	rv += '-'
	for row in $board.dimensions.y:
		var line := '\n'
		for col in $board.dimensions.x:
			var av = avatars[Vector2i(col, row)]
			if av.id == 'player':
				line += '0'
			elif av.id == 'bot':
				line += '1'
			elif av.id == 'mine':
				line += 'x'
			else:
				line += '.'
		rv += line

	return rv

func set_code(c):
	_code = c


func _on_play_pressed():
	emit_signal('generated_level', generate_code())
	emit_signal('swapped_to', preload("res://scenes/play.tscn"))


func _on_title_pressed():
	emit_signal('swapped_to', preload('res://scenes/title.tscn'))
