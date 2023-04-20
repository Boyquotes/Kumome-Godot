extends Player
class_name PlayerAI

func move():
	avatar.thinking = true
	var potentials : Array[Vector2i] = []
	for m in game.get_opens():
		if abs(m.x - location.x) <= 1 and abs(m.y - location.y) <= 1:
			potentials.append(m)
	var spot := pick_a_move_spot(potentials)

	if not stuck:
		avatar.create_tween().tween_callback(move_to.bind(spot)).set_delay(0.5)
	else:
		play_stuck()

func place():
	if stuck:
		return cant_place()


	avatar.thinking = true
	var potentials : Array[Vector2i] = game.get_opens()
	var spot := pick_a_mine_spot(potentials)

	avatar.create_tween().tween_callback(place_at.bind(spot)).set_delay(0.5)

func what_if_move(hyp : Hypothetical, from : Vector2i, to : Vector2i) -> int:
	return hyp.what_if_move(from, to).score_for_team(team)

func what_if_mine(hyp : Hypothetical, _from : Vector2i, at : Vector2i) -> int:
	return hyp.what_if_mine(at).score_for_team(team)

func pick_a_spot(potentials : Array[Vector2i], scorer : Callable) -> Vector2i:
	if len(potentials) == 0:
		stuck = true
		return Vector2i.ZERO

	var hyp : Hypothetical = game.get_hypothetical()
	var best_score := -10000
	var bests : Array[Vector2i] = []
	for pot in potentials:
		var new_score = scorer.call(hyp, location, pot)
		if new_score > best_score:
			best_score = new_score
			bests = []

		if new_score == best_score:
			bests.append(pot)

	return pick_at_random(bests)

func pick_a_move_spot(potentials : Array[Vector2i]) -> Vector2i:
	return pick_a_spot(potentials, what_if_move)

func pick_a_mine_spot(potentials : Array[Vector2i]) -> Vector2i:
	return pick_a_spot(potentials, what_if_mine)

func pick_at_random(potentials : Array[Vector2i]) -> Vector2i:
	if len(potentials):
		return potentials[randi() % len(potentials)]
	else:
		stuck = true
		return Vector2i.ZERO
