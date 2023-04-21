extends Node2D

signal selected

func init(card : Card):
	var titles := []
	for action in card.queue:
		titles.append(action.title)

	if len(titles) == 1:
		$Label.text = titles[0]
	elif len(titles) == 2 and titles[0] == titles[1]:
		$Label.text = '%s\nx 2' % titles[0]
	elif len(titles) == 2:
		$Label.text = '%s\n+\n%s' % titles
	elif  len(titles) == 3:
		$Label.text = '%s\n%s\n%s' % titles
	else:
		$Label.text = '?'

func _ready():
	display(false)

func display(b : bool):
	visible = b

func _on_button_pressed():
	emit_signal('selected')


