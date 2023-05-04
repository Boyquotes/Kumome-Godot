extends Card
class_name CardDummy

func _init(_data : Dictionary):
	queue = [null]

func create_avatar():
	pass

func act(_pl : Player):
	pass

func perform_action(_pl):
	pass

func discard():
	emit_signal('finished')
	queue_free()


func add_action(_a : String, _m : String):
	pass
