extends Action

func _init():
	title = 'Move'

func act(pl : Player):
	do(pl, pl.move)
