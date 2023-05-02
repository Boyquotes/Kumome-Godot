@tool
extends Control

signal selected

@export var card_art : Texture = preload("res://imgs/card_art/placeholder.png") :
	set(x):
		card_art = x
		refresh()

@export var cost : int = 1 :
	set(x):
		cost = x
		refresh()

@export var title : String = '' :
	set(x):
		title = x
		refresh()

@export_multiline var short_description : String = '' :
	set(x):
		short_description = x
		refresh()

@export_multiline var long_description : String = '' :
	set(x):
		long_description = x
		refresh()

@export_multiline var notes : String = '' :
	set(x):
		notes = x
		refresh()

@export_multiline var export : String = ''

var active := false


func _ready():
	if Engine.is_editor_hint():
		refresh()
	else:
		display(false)
		refresh()

func init(card : Card):
	var titles := []
	for action in card.queue:
		titles.append(action.title)

	if len(titles) == 1:
		$title.text = titles[0]
	elif len(titles) == 2 and titles[0] == titles[1]:
		$title.text = '%s x 2' % titles[0]
	elif len(titles) == 2:
		$title.text = '%s + %s' % titles
	elif  len(titles) == 3:
		$title.text = '%s %s %s' % titles
	else:
		$title.text = '?'

func refresh():
	if not is_inside_tree(): return

	print(title)

	$title.text = title
	$description.text = short_description
	$art.texture = card_art
	$cost.frame = clampi(cost, 0, $cost.hframes - 1)

	export = str({
		'art': card_art.resource_path,
		'title': title,
		'cost': cost,
		'short_description': short_description,
		'long_description': long_description,
		'notes': notes
	})


func display(b : bool):
	active = b
	modulate.a = 1 if b else 0.5

func _on_button_pressed():
	if not active: return
	emit_signal('selected')


