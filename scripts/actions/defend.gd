extends Action

func _init(_title : String, _mod : String):
	mod = _mod
	title = _title

func act(pl : Player):
	do(pl, pl.defend.bind(parse_attack_defend_mod()))
