extends Control

var level_code := ''
var editing := true
var active_scene

func _ready():
	swap_to_puzzle()

func swap_to_puzzle():
	swap_to(preload("res://scenes/puzzle_editor.tscn"))

func swap_to_play():
	swap_to(preload("res://scenes/play.tscn"))

func swap_to(scene):
	if active_scene != null:
		active_scene.queue_free()

	active_scene = scene.instantiate()
	active_scene.level_code = level_code
	add_child(active_scene)

func _on_button_pressed():
	level_code = active_scene.level_code
	if editing:
		swap_to_play()
		$Button.text = 'Edit'
		editing = false
	else:
		swap_to_puzzle()
		$Button.text = 'Play'
		editing = true
