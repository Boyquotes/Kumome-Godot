extends Action

func act(pl : Player):
	do(pl, pl.perform_special_action.bind('unmine'))
