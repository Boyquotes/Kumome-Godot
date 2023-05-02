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

func card_override(c : Card) -> bool:
	if c.cost > mana:
		return false

	clear_touch_spots()
	super(c)

	return true

# move(), place(), teleport(), and unmine() all work pretty much the same way: get a list of potential
# points for touch_sports from game, throw out any point that isn't appropriate, change the phase (for
# use later in on_touch_spot_touched()) and add the touch_spots to the board.

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

func perform_special_action(key : String, _args = null):
	if key == 'unmine':
		unmine()
	elif key == 'teleport':
		teleport()
	else:
		super(key)

# This method is called when a touch_spot emits the "touched" signal. It's now up to this class
# to decide what to do
func on_touch_spot_touched(at : Vector2i):
	# This signal is to tell the UI to hide the cards; now that we've commited to whatever,
	# we can't change our mind and play a different card.
	emit_signal('commited_to_action')

	# Not that we've toouched a spot, we can't touch another, so get rid of them!
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

# The touch spots are the little targets that appear on the board and wait for player input.
# They emit the signal "touched" when touched, and don't do much more than that.
func add_touch_spots(spot_list):
	for pot_spot in spot_list:
		var touch_spot = preload("res://scenes/touch_spot.tscn").instantiate()
		touch_spot.location = pot_spot
		touch_spot.size = game.board.square_size
		touch_spot.modulate = color
		touch_spot.position = game.board.to_position(pot_spot)
		touch_spots.append(touch_spot)
		touch_spots_node.add_child(touch_spot)

		touch_spot.connect('touched', on_touch_spot_touched)
