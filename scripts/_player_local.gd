extends Player
class_name PlayerHuman

enum PHASE {
	#Basic
	REST, MOVE, PLACE, STUCK,

	#Special
	UNMINE, TARGET, CHARGE
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

	var potentials : Array[Vector2i] = game.get_spots_adjacent_to_players([self])

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

func target(mod):
	phase = PHASE.TARGET
	avatar.thinking = true
	if mod == 'SELF':
		await avatar.get_tree().process_frame
		await avatar.get_tree().process_frame

		emit_signal('finished')
	else:
		push_warning('Target: %s not implemented' % mod)

func teleport(mod):
	avatar.thinking = true

	var potentials : Array[Vector2i]
	if mod == '_':
		potentials = game.get_opens()
	elif mod == 'PLAYER':
		potentials = game.get_spots_adjacent_to_players(game.players)
	elif mod == 'OTHER':
		var others = game.players.duplicate()
		others.erase(self)
		potentials = game.get_spots_adjacent_to_players(others)
	elif mod == 'EDGE':
		potentials = game.get_edge_spots()
	else:
		push_warning('Teleport to %s not implemented' % mod)

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

func charge(mod : String):
	phase = PHASE.CHARGE
	avatar.thinking = true
	var dir := Vector2i.ZERO

	if 'N' in mod:
		dir.y = -1
	elif 'S' in mod:
		dir.y = 1

	if 'E' in mod:
		dir.x = 1
	elif 'W' in mod:
		dir.x = -1

	var ray : Array[Vector2i] = game.get_ray(location + dir, dir)
	var mines : Array[Mine] = []
	for mine in game.mines.duplicate():
		if mine.location in ray:
			game.remove_mine_at(mine.location)

	if len(ray) > 0:
		move_to(ray[-1])
	else:
		move_to(location)

func perform_special_action(key : String, mod = null):
	if key == 'unmine':
		unmine()
	elif key == 'teleport':
		teleport(mod)
	elif key == 'target':
		target(mod)
	elif key == 'charge':
		charge(mod)
	else:
		super(key)

# This method is called when a touch_spot emits the "touched" signal. It's now up to this class
# to decide what to do
func on_touch_spot_touched(at : Vector2i):
	# This signal is to tell the UI to hide the cards; now that we've commited to whatever,
	# we can't change our mind and play a different card.
	emit_signal('commited_to_action')

	# Now that we've touched a spot, we can't touch another, so get rid of them!
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
