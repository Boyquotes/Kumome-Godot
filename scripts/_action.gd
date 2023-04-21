extends Node
class_name Action

signal finished

var title : String

func act(pl : Player):
	emit_signal('finished')

func do(pl : Player, what : Callable, args := []):
	pl.connect('finished', emit_signal.bind('finished'))
	what.callv(args)

func _to_string():
	return title
