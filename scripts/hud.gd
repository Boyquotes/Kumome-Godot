extends Control

var players : Array[Player] = []
var teams : Array[int] = []

@onready var grid = $center/grid


func register_player(pl : Player):
	players.append(pl)
	if not pl.team in teams:
		teams.append(pl.team)

func setup():
	if len(players) == len(teams):
		generate_free_for_all()
	else:
		generate_teams()

func generate_teams():
	for team in teams:
		var het = preload("res://scenes/hud_element_team.tscn").instantiate()
		grid.add_child(het)
		het.team = team

		for player in players:
			if player.team != team:
				continue

			var hep = preload("res://scenes/hud_element_player.tscn").instantiate()
			hep.attach_player(player)
			het.add_hep(hep)

func generate_free_for_all():
	if len(players) == 5 or len(players) == 6:
		grid.columns = 3
	else:
		grid.columns = 4

	for player in players:
		var hep = preload("res://scenes/hud_element_player.tscn").instantiate()
		hep.attach_player(player)
		grid.add_child(hep)

