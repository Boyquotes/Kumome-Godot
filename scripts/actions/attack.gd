extends Action

func _init(_title : String, _mod):
	mod = _mod
	title = _title

func act(pl : Player):
	do(pl, pl.attack.bind(parse_attack_defend_mod()))
