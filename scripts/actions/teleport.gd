extends Action

func _init():
	title = 'Beam\nMe\nUp!'

func act(pl : Player):
	do(pl, pl.perform_special_action.bind('teleport'))
