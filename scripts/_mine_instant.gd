extends Mine
class_name MineInstant

func _init():
	avatar = preload("res://scenes/avatar_instant.tscn").instantiate()
	avatar.texture = texture

