extends Node
class_name Mine

var texture := preload("res://imgs/mine.png")

var location : Vector2i
var avatar = preload("res://scenes/avatar.tscn").instantiate()
var game : Game

func _init(_game):
	avatar.texture = texture
	game = _game

func destroy():
	avatar.destroy()

func move_to(to : Vector2i):
	location = to
	avatar.move_to(game.board.to_position(location), func(): pass)
