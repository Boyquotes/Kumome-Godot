extends Node
class_name Action

# Abstract class, must be overriden and should not be used directly.
# See any script in "res://scripts/actions/" for examples

signal finished

var mod : String
var title : String

func _init(_title : String, _mod : String):
	mod = _mod
	title = _title

# Override this in the subclass to give functionality
func act(_pl : Player):
	emit_signal('finished')

# Useful to the subclass when overriding act()
func do(pl : Player, what : Callable):
	pl.connect('finished', emit_signal.bind('finished'))
	what.call()

func _to_string():
	return '<%s %s>' % [title, mod]
