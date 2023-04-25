extends PlayerAI
class_name PlayerAIInstant

# This class is the same as PlayerAI but without all those pesky animations. It's good for testing
# but isn't used for anything else.

func add_avatar():
	avatar = preload("res://scenes/avatar_instant.tscn").instantiate()
	avatar.connect('finished', on_avatar_finished)

func move():
	avatar.thinking = true
	var potentials : Array[Vector2i] = []
	for m in game.get_opens():
		if abs(m.x - location.x) <= 1 and abs(m.y - location.y) <= 1:
			potentials.append(m)
	var spot := pick_a_move_spot(potentials)

	if not stuck:
		move_to.call_deferred(spot)
	else:
		play_stuck()

func place():
	if stuck:
		return cant_place()

	avatar.thinking = true
	var potentials : Array[Vector2i] = game.get_opens()
	var spot := pick_a_mine_spot(potentials)

	place_at.call_deferred(spot)

func move_to(to : Vector2i):
	turns += 1
	avatar.thinking = false
	location = to

	avatar.position = game.board.to_position(location)
	emit_signal.call_deferred('finished')


func place_at(at : Vector2i):
	avatar.thinking = false
	game.add_instant_mine_at(at, color)
	emit_signal.call_deferred('finished')


