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
var key := 1
var avatar : Control
var cost : int = 2
var data : Dictionary


func _init(_data : Dictionary):
	data = _data
	cost = data.cost
	for i in range(1, 4):
		var a = data.get('action_%s' % i, '_')
		var m = data.get('modifier_%s' % i, '_')
		add_action(a, m)
	create_avatar()

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
	var action : Action = queue.pop_front()
	action.connect('finished', act.bind(pl))
	action.act(pl)

func discard():
	emit_signal('finished')
	queue_free()
	return

func add_action(a : String, m : String):
	if a == '_': return
	var action : Action = actions.get(a, actions.special).new(a, m)

	queue.append(action)
