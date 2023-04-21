extends Action

func _init():
	title = 'Mine'

func act(pl : Player):
	do(pl, pl.place)
