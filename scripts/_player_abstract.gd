extends Node
class_name Player

# This class handles all the logic/decision making for any player (bot/local/remote)
# It should be subclassed (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
# It has an avatar which is the visual representation. Don't waste time looking at
# "res://scripts/avatar.gd" just know that that class handles animations and whatnot and emits
# the "finished" signal when it's done animating


signal finished
signal card_finished
signal commited_to_action

var avatar
var team : int
var location : Vector2i
var game : Game
var stuck : bool = false
var theme : Global.AVATARS = Global.AVATARS.BLACK
var id : int
var turns := 0
var card : Card
var special_cards_count := 0

var color : Color

func _init(_theme : Global.AVATARS, _team : int):
	team = _team
	add_avatar()
	theme = _theme
	set_theme()

# I'm ashamed of what I've done here.
func set_theme():
	match theme:
		Global.AVATARS.RED:
			avatar.texture = preload("res://imgs/lightning.png")
			color = Color.RED
		Global.AVATARS.YELLOW:
			avatar.texture = preload("res://imgs/happy.png")
			color = Color.YELLOW
		Global.AVATARS.WHITE:
			avatar.texture = preload("res://imgs/king.png")
			color = Color.WHITE
		Global.AVATARS.BLACK:
			avatar.texture = preload("res://imgs/diamond.png")
			color = Color.BLACK
		Global.AVATARS.BOT:
			avatar.texture = preload("res://imgs/bot.png")
			color = Color.GRAY
		Global.AVATARS.BEAR:
			avatar.texture = preload("res://imgs/animals/bear.png")
			color = Color('#a9b9e1')
		Global.AVATARS.CHICKEN:
			avatar.texture = preload("res://imgs/animals/chicken.png")
			color = Color('#85c773')
		Global.AVATARS.SNAKE:
			avatar.texture = preload("res://imgs/animals/snake.png")
			color = Color('#e3c375')
		Global.AVATARS.ELEPHANT:
			avatar.texture = preload("res://imgs/animals/elephant.png")
			color = Color('#d99696')
		Global.AVATARS.MONKEY:
			avatar.texture = preload("res://imgs/animals/monkey.png")
			color = Color.SADDLE_BROWN
		Global.AVATARS.RHINO:
			avatar.texture = preload("res://imgs/animals/rhino.png")
			color = Color.GRAY
		Global.AVATARS.OWL:
			avatar.texture = preload("res://imgs/animals/owl.png")
			color = Color.BLANCHED_ALMOND
		Global.AVATARS.WALRUS:
			avatar.texture = preload("res://imgs/animals/walrus.png")
			color = Color.SALMON

func add_avatar():
	avatar = preload("res://scenes/avatar.tscn").instantiate()
	avatar.connect('finished', on_avatar_finished)

func add_card(c : Card):
	card = c
	card.connect('finished', emit_signal.bind('card_finished'))

# By default, play the card move/mine
func play_card():
	add_card(preload("res://scripts/cards/move_mine.gd").new())
	card.act(self)

# Allows you to override the played card so that when you start your turn with play_card(), you
# can then play a different card (e.g. teleport). The UI prevents this from being called by a
# local player at an inappropriate time, but I think that might be error prone.
func card_override(c : Card):
	special_cards_count += 1
	card.queue_free()
	add_card(c)
	card.act(self)

# Called to tell the class to begin the move process.
# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func move():
	pass

# Called when a move decision has actually been made by the subclass
func move_to(to : Vector2i):
	turns += 1
	avatar.thinking = false
	location = to
	avatar.move_to(game.board.to_position(location), emit_signal.bind('finished'))

# Called to tell the class to begin the mine placing process
# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func place():
	pass

# Called when a mine placing decision has actually been made by the subclass
func place_at(at : Vector2i):
	avatar.thinking = false
	var mine := game.add_mine_at(at, color)
	mine.avatar.connect('finished', emit_signal.bind('finished'))

func remove_mine_at(at : Vector2i):
	avatar.thinking = false
	var mine_maybe : Array[Mine] = game.remove_mine_at(at)
	if len(mine_maybe):
		for mine in mine_maybe:
			if not mine.avatar.is_connected('finished', emit_signal.bind('finished')):
				mine.avatar.connect('finished', emit_signal.bind('finished'))
	else:
		emit_signal.call_deferred('finished')

# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func perform_special_action(action_key : String, extra_args = null):
	push_warning(self, 'can not perform special action', action_key)
	emit_signal.call_deferred('finished')

func cant_place():
	avatar.thinking = false
	#emit_signal('finished')

func on_avatar_finished():
	if stuck:
		emit_signal('finished')
		emit_signal('card_finished')

func play_stuck():
	#emit_signal('got_stuck')
	avatar.play_stuck()

# Useful for debugging purposes
func _to_string():
	return {
		Global.AVATARS.RED : 'Red Lightning',
		Global.AVATARS.YELLOW: 'Smiley',
		Global.AVATARS.BLACK: 'Black Diamond',
		Global.AVATARS.WHITE: 'The King',
		Global.AVATARS.BOT: 'Bot'
	}.get(theme, '')
