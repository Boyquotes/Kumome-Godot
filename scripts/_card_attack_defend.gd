extends Card
class_name CardAttackDefend

enum {
	ATTACK = 10, DEFEND = 13
}

#signal finished
#signal selected
#
#
#var actions := {
#	move = preload("res://scripts/actions/move.gd"),
#	mine = preload("res://scripts/actions/mine.gd"),
#	special = preload("res://scripts/actions/special.gd")
#}
#
#var queue : Array[Action] = []
#var key : int : get = get_key
#var _key : int = -1
#var avatar : Control
#var cost : int = 2
#var data : Dictionary
#var active_action : Action
var indices : Array[int] = []
var mode := ATTACK

func _init(k : int):
	_key = k

	for _i in 12:
		indices.push_front(k % 16)
		k /= 16

	cost = k % 16
	k /= 16
	cost = 1 # override for playtesting

	var ad = k % 16
	assert(ad == ATTACK or ad == DEFEND, 'Attack/Defend card is neither Attack nor Defend')
	if ad == ATTACK:
		mode = ATTACK
		add_action('attack', get_mod(), _key)
	elif ad == DEFEND:
		mode = DEFEND
		add_action('defend', get_mod(), _key)

	k /= 16

	assert(k == 2, 'Version not 2')

	create_avatar()

func get_mod() -> String:
	var dirs := Global.action_defend_rel_dirs
	var list : Array[String] = []
	var pri := dirs[indices[0] - 1]

	for index in indices.slice(1):
		if index == 0:
			continue
		var dir := dirs[index - 1] - pri
		list.append('%s,%s' % [dir.x, dir.y])

	return '|'.join(list)

func get_key() -> int:
	return _key

func create_avatar():
	avatar = preload("res://scenes/avatar_attack_defend.tscn").instantiate()
	avatar.init.call_deferred(self)
	avatar.connect('selected', emit_signal.bind('selected'))
	avatar.cost = cost

func act(pl : Player):
	if len(queue) == 0:
		discard()
	else:
		perform_action(pl)


