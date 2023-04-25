extends Node
class_name Action

# Abstract class, must be overriden and should not be used directly.
# See any script in "res://scripts/actions/" for examples

signal finished

var title : String

# Override this in the subclass to give functionality
func act(pl : Player):
	emit_signal('finished')

# Useful to the subclass when overriding act()
func do(pl : Player, what : Callable, args := []):
	pl.connect('finished', emit_signal.bind('finished'))
	what.callv(args)

func _to_string():
	return title
