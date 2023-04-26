extends Control

var active_scene : SwapScene
var saved_level : String
var quit_to : PackedScene = preload("res://scenes/title.tscn")

func _ready():
	await get_tree().process_frame

	if Global.active_user.logged_in:
		swap_to_scene(preload("res://scenes/title.tscn"))
	else:
		swap_to_scene(preload("res://scenes/create_account.tscn"))

func swap_to_scene(scene : PackedScene):
	if active_scene != null:
		active_scene.queue_free()

	active_scene = scene.instantiate()
	active_scene.connect('swapped_to', swap_to_scene)
	active_scene.connect('generated_level', save_level)
	active_scene.connect('requested_level', on_level_request)
	active_scene.connect('quit', on_quit)
	active_scene.connect('changed_quit_to', on_change_quit_to)

	add_child(active_scene)

func save_level(lvl):
	saved_level = lvl

func on_level_request(callback : Callable):
	callback.call(saved_level)

func on_quit():
	swap_to_scene(quit_to)

func on_change_quit_to(ps : PackedScene):
	quit_to = ps
