extends Action

func _init():
	title = 'Unmine'

func act(pl : Player):
	do(pl, pl.perform_special_action.bind('unmine'))
