extends PanelContainer

var team : int :
	set(t):
		team = t
		if is_inside_tree():
			$VBoxContainer/Label.text = 'Team %s' % 'ABCDEFGH'[team]

func add_hep(hep):
	$VBoxContainer.add_child(hep)
