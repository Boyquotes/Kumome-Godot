extends Player
class_name PlayerHuman

enum PHASE {
	#Basic
	REST, MOVE, PLACE, STUCK,

	#Special
	UNMINE
}

var touch_spots := []
var touch_spots_node : Node2D
var phase = PHASE.REST

func card_override(c : Card):
	clear_touch_spots()
	super(c)

func move():
	avatar.thinking = true

	var potentials : Array[Vector2i] = []
	for m in game.get_opens():
		if abs(m.x - location.x) <= 1 and abs(m.y - location.y) <= 1:
			potentials.append(m)

	if len(potentials):
		add_touch_spots(potentials)
		phase = PHASE.MOVE
	else:
		phase = PHASE.STUCK
		stuck = true
		play_stuck()


func place():
	if stuck: return cant_place()

	avatar.thinking = true

	var potentials : Array[Vector2i] = game.get_opens()

	add_touch_spots(potentials)

	phase = PHASE.PLACE

func teleport():
	avatar.thinking = true

	var potentials : Array[Vector2i] = game.get_opens()

	if len(potentials):
		add_touch_spots(potentials)
		phase = PHASE.MOVE
	else:
		phase = PHASE.STUCK
		stuck = true
		play_stuck()

func unmine():
	avatar.thinking = true

	var potentials : Array[Vector2i] = game.get_mine_spots()

	add_touch_spots(potentials)

	phase = PHASE.UNMINE

func perform_special_action(key : String, args = null):
	print('special ', key)
	if key == 'unmine':
		unmine()
	elif key == 'teleport':
		teleport()
	else:
		super(key)

func on_touch_spot_touched(at : Vector2i):
	emit_signal('commited_to_action')
	clear_touch_spots()

	if phase == PHASE.MOVE:
		move_to(at)
	elif phase == PHASE.PLACE:
		place_at(at)
	elif phase == PHASE.UNMINE:
		remove_mine_at(at)

	phase = PHASE.REST

func clear_touch_spots():
	while touch_spots:
		var ts = touch_spots.pop_back()
		ts.queue_free()

func add_touch_spots(potentials):
	for pot_spot in potentials:
		var touch_spot = preload("res://scenes/touch_spot.tscn").instantiate()
		touch_spot.location = pot_spot
		touch_spot.size = game.board.square_size
		touch_spot.modulate = color
		touch_spot.position = game.board.to_position(pot_spot)
		touch_spots.append(touch_spot)
		touch_spots_node.add_child(touch_spot)

		touch_spot.connect('touched', on_touch_spot_touched)
