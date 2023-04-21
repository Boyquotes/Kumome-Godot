extends Node
class_name Mine

var texture := preload("res://imgs/mine.png")

var location : Vector2i
var avatar = preload("res://scenes/avatar.tscn").instantiate()


func _init():
	avatar.texture = texture

func destroy():
	avatar.destroy()
