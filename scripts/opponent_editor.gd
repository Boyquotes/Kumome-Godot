@tool
extends HBoxContainer

@export var player_name : String = '' :
	set(pn):
		player_name = pn
		refresh()

@export var index : int :
	set(ind):
		index = ind
		refresh()

@export var nature : int :
	set(ch):
		nature = ch
		refresh()

@export var team : int :
	set(tm):
		team = tm
		refresh()

func _ready():
	refresh()

	$name_label.set.call_deferred("custom_minimum_size", $nature.size)
	if Engine.is_editor_hint():
		return

#	$nature.connect('item_selected', update_value.bind('nature'))
#	$team.connect('item_selected', update_value.bind('team'))

func get_data() -> Dictionary:
	return {
		'nature' : 'L' if player_name else ['B', 'L', ''][$nature.selected],
		'player' : player_name,
		'team': $team.selected
	}

func update_value(value, key):
	set(key, value)

func refresh():
	if not is_inside_tree(): return
	$flavor_label.text = 'P%s ' % index
	$nature.selected = nature
	$team.selected = team
	$team.disabled = nature == 2

	$name_label.text = player_name
	$name_label.visible = player_name != ''
	$nature.visible = player_name == ''


func _on_nature_item_selected(index):
	$team.disabled = index == 2
