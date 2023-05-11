extends Control

signal selected

enum {ATTACK, DEFEND}

var card : CardAttackDefend
var active : bool
var mode := ATTACK

var cost : int :
	set(x):
		cost = x
		if is_inside_tree():
			$cost.frame = clampi(cost, 0, $cost.hframes - 1)

func init(_card : CardAttackDefend):
	card = _card
	var pri : int
	var add : int
	if card.mode == card.ATTACK:
		mode = ATTACK
		pri = 1
		add = 3
		$title.text = 'Attack'
	elif card.mode == card.DEFEND:
		mode = DEFEND
		pri = 2
		add = 4
		$title.text = 'Defend'

	for i in $mines.get_child_count():
		var child = $mines.get_child(i)
		if (i+1) == card.indices[0]:
			child.frame = pri
		elif (i+1) in card.indices:
			child.frame = add
		else:
			child.frame = 0


func display(b : bool):
	active = b
	modulate.a = 1.0 if b else 0.5

func _on_button_pressed():
	if not active: return
	emit_signal('selected')
