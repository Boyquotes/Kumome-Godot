extends SwapScene

# This script does all the heavy lifting of connecting the game, the players, their avatars,
# the board, and the ui. It doesn't handle any logic (see "res://scripts/_game.gd" for that).
# This script is not properly commented because 1. I think it'll be completly rewritten at some point
# and 2. every method does pretty much exactly what is says it does.

var level_code : String
@export var run_ai_test := 0

var game : Game
var win_record := {}

# Hard coded for testing purposes. Obviously there's a better way to do it!
var deck : Array[Card] = []

func _ready():

	#########################################################
	# Yannis: You can change this line:
	var card_indices := [1, 4, 20, 21]
	##########################################################

	for i in card_indices:
		deck.append(Global.get_card(i))

	add_cards()
	space_cards()

	if get_tree().root == self.get_parent():
		create(level_code)
	else:
		emit_signal('requested_level', create)

	if run_ai_test:
		create(level_code)

func create(lc : String):
	level_code = lc

	clear_children([$avatars, $mines])

	var data = Global.parse_code(level_code, {
		'L': create_local_player,
		'B': create_ai_player,
		'I': create_ai_instant_player
	})

	game = Game.new($board, data.size)

	game.connect('added_mine', add_mine_to_tree)
	game.connect('game_over', on_game_over)
	game.connect('phase_change', update_ui)
	game.connect('turn_started', on_turn_start)
	game.connect('commited_to_action', show_cards.bind(false))

	for obj in data.map:
		if obj.player:
			obj.constructor.call(obj.color, obj.team, obj.loc)
		else:
			add_mine_at(obj.loc)

	$ui/hud.setup()
	game.start()

func on_turn_start(player : Player):
	space_cards()
	show_cards(player is PlayerHuman)
	update_mana()

func update_mana():
	if not game.active_player is PlayerHuman:
		return

	await get_tree().process_frame
	$mana.text = 'Mana: %s' % game.active_player.mana

func show_cards(b : bool):

	for ca in $cards.get_children():
		ca.display(b and Global.settings.playing_with_cards)

func update_ui():
	$ui/player.texture = game.active_player.avatar.texture

func create_local_player(id : int, team : int, at : Vector2i) -> PlayerHuman:
	var player := PlayerHuman.new(id, team)
	player.touch_spots_node = $touch_spots
	create_player(player, at)
	return player

func create_ai_player(id : int, team : int, at : Vector2i) -> PlayerAI:
	var player := PlayerAI.new(id, team)
	create_player(player, at)
	return player

func create_ai_instant_player(id : int, team : int, at : Vector2i) -> PlayerAIInstant:
	var player := PlayerAIInstant.new(id, team)
	create_player(player, at)
	return player

func create_player(player : Player, at : Vector2i):
	place_player(player, at)
	$avatars.add_child(player.avatar)
	$ui/hud.register_player(player)

func create_avatar(tex : Texture):
	var avatar = preload("res://scenes/avatar.tscn").instantiate()
	avatar.texture = tex
	$avatars.add_child(avatar)
	return avatar

func place_player(player, at):
	player.location = at
	game.add_player(player)
	player.avatar.position = $board.to_position(at)

func add_mine_at(at : Vector2i):
	game.add_mine_at(at)

func add_mine_to_tree(mine : Mine):
	$mines.add_child(mine.avatar)

func on_game_over():
	var winning_team = game.get_winning_team()
	if run_ai_test:
		if not winning_team in win_record:
			win_record[winning_team] = 0
		win_record[winning_team] += 1
		run_ai_test -= 1
		$ui/win_record.text = '%s - %s' % [win_record.get(0, 0), win_record.get(1, 0)]
		create(level_code)
	else:
		$ui/game_over.text = 'Team %s Wins!' % 'ABCDEFG'[winning_team]

func clear_children(list : Array[Node]):
	for node in list:
		for child in node.get_children():
			child.queue_free()

func add_cards():
	for card in deck:
		$cards.add_child(card.avatar)
		card.connect('selected', on_card_selected.bind(card))

func on_card_selected(card : Card):
	var can_afford = game.active_player.card_override(card)
	if can_afford:
		update_mana()
		card.avatar.queue_free()
		show_cards(false)

func space_cards():
	var count = $cards.get_child_count()
	if count == 0:
		return

	var width = $cards.get_child(0).size.x
	var marg = (size.x - width*count)/(count + 1)
	for i in count:
		$cards.get_child(i).position.x = marg + (width + marg)*i

func _on_quit_pressed():
	emit_signal('quit')
