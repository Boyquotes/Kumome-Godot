extends Node
class_name Card

signal finished
signal selected

var ACTIONS := {
	MOVE = preload("res://scripts/actions/move.gd"),
	MINE = preload("res://scripts/actions/mine.gd"),
	UNMINE = preload("res://scripts/actions/unmine.gd"),
	TELEPORT = preload("res://scripts/actions/teleport.gd")
}

var queue : Array[Action] = []
var id := randi() % 1000
var avatar : Node2D

func _init():
	add_actions()
	create_avatar()

func add_actions():
	pass

func create_avatar():
	avatar = preload("res://scenes/avatar_card.tscn").instantiate()
	avatar.init(self)
	avatar.connect('selected', emit_signal.bind('selected'))

func act(pl : Player):
	prints('act', queue)
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

func add_action(a : Script):
	queue.append(a.new())
