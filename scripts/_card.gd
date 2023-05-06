extends Node
class_name Card

# This is the super class for all cards, and it shouldn't be used directly, but rather subclassed.
# (See any script in "res://scripts/cards/" for examples).

signal finished
signal selected


var actions := {
	move = preload("res://scripts/actions/move.gd"),
	mine = preload("res://scripts/actions/mine.gd"),
	special = preload("res://scripts/actions/special.gd")
}

var queue : Array[Action] = []
var key : int : get = get_key
var _key : int = -1
var avatar : Control
var cost : int = 2
var data : Dictionary
var active_action : Action


func _init(_data : Dictionary):
	data = _data
	cost = data.cost
	for i in range(1, 5):
		var a = data.get('action_%s' % i, '_')
		var m = data.get('modifier_%s' % i, '_')
		add_action(a, m)
	create_avatar()


func get_key() -> int:
	if _key != -1:
		return _key

	_key = 0
	shift_key(2)
	shift_key(1)
	shift_key(cost)
	for i in 3:
		if i < len(queue):
			shift_key(queue[i].key, 4)
		else:
			shift_key(0, 4)

	return _key

func get_pretty_key() -> String:
	var s = String.num_int64(key, 16)
	return '%s|%s|%s|%s|%s|%s' % [s[0], s[1], s[2], s.substr(3,4), s.substr(7,4), s.substr(11,4)]


func shift_key(value : int, steps := 1):
	for _i in steps:
		_key *= 16
	_key += value

func create_avatar():
	avatar = preload("res://scenes/avatar_card.tscn").instantiate()
	avatar.init.call_deferred(self)
	avatar.connect('selected', emit_signal.bind('selected'))
	avatar.cost = cost

func act(pl : Player):
	if len(queue) == 0:
		discard()
	else:
		perform_action(pl)

func perform_action(pl):
	active_action = queue.pop_front()
	active_action.connect('finished', act.bind(pl))
	active_action.act(pl)

func discard():
	emit_signal('finished')
	queue_free()
	return

func add_action(a : String, m : String):
	if a == '_': return
	var action : Action = actions.get(a, actions.special).new(a, m)

	queue.append(action)
