extends Player
class_name PlayerHuman

enum PHASE {REST, MOVE, PLACE, STUCK}

var touch_spots := []
var touch_spots_node : Node2D
var phase = PHASE.REST

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

func on_touch_spot_touched(at : Vector2i):
	while touch_spots:
		var ts = touch_spots.pop_back()
		ts.queue_free()

	if phase == PHASE.MOVE:
		move_to(at)
	elif phase == PHASE.PLACE:
		place_at(at)

	phase = PHASE.REST


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
