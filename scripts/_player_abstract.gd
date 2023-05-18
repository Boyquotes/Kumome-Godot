extends Node
class_name Player

# This class handles all the logic/decision making for any player (bot/local/remote)
# It should be subclassed (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
# It has an avatar which is the visual representation. Don't waste time looking at
# "res://scripts/avatar.gd" just know that that class handles animations and whatnot and emits
# the "finished" signal when it's done animating

enum {
	INVISIBLE = 1,
	DARKNESS = 2,
	POISONED = 4,
	FROZEN = 8
}

signal finished
signal card_finished
signal commited_to_action
signal sent

var avatar
var team : int
var location : Vector2i
var game : Game
var stuck : bool = false
var theme : Global.AVATARS = Global.AVATARS.BLACK
var id : String
var turns := 0
var card : Card
var mana := 0
var effects := 0
var is_active : bool :
	get:
		return len(card.queue) > 0

var color : Color
var attack_defend_rel_spots : Array[Vector2i]

func _init(_theme : Global.AVATARS, _team : int, _id : String):
	id = _id
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
	mana += 1
	add_card(Global.get_card(0))
	card.act(self)

# Allows you to override the played card so that when you start your turn with play_card(), you
# can then play a different card (e.g. teleport). The UI prevents this from being called by a
# local player at an inappropriate time, but I think that might be error prone.
func card_override(c : Card) -> bool:
	if c.cost > mana:
		return false

	mana -= c.cost
	card.queue_free()
	add_card(c)
	card.act(self)
	return true

# Called to tell the class to begin the move process.
# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func move():
	pass

# Called when a move decision has actually been made by the subclass
func move_to(to : Vector2i, send := true):
	turns += 1
	avatar.thinking = false
	location = to
	if send:
		avatar.move_to(game.board.to_position(location), emit_signal.bind('finished'))
		send_action(true)
	else:
		avatar.move_to(game.board.to_position(location), func() : pass)
		send_action(false)

# Called to tell the class to begin the mine placing process
# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func place():
	pass

# Called when a mine placing decision has actually been made by the subclass
func place_at(at : Vector2i, send := true):
	avatar.thinking = false
	var mines := game.add_mine_at(at, color)
	if len(mines):
		for mine in mines:
			mine.avatar.connect('finished', emit_signal.bind('finished'))
	else:
		emit_signal.call_deferred('finished')
	send_action(send)

func attack(spots : Array[Vector2i]):
	prints('attack', spots)

func attack_at(at : Vector2i, send := true):
	place_at(at, false)
	for dir in attack_defend_rel_spots:
		place_at(at + dir, false)
	send_action(send)

func defend(spots : Array[Vector2i]):
	prints('defend', spots)

func defend_at(at : Vector2i, send := true):
	remove_mine_at(at, false)
	for dir in attack_defend_rel_spots:
		remove_mine_at(at + dir, false)
	send_action(send)

func remove_mine_at(at : Vector2i, send := true):
	avatar.thinking = false
	var mine_maybe : Array[Mine] = game.remove_mine_at(at)
	if len(mine_maybe):
		for mine in mine_maybe:
			if not mine.avatar.is_connected('finished', emit_signal.bind('finished')):
				mine.avatar.connect('finished', emit_signal.bind('finished'))
	else:
		emit_signal.call_deferred('finished')
	send_action(send)

func play_stuck():
	add_card(CardStuck.new())
	card.act(self)

func act_stuck(send := true):
	avatar.play_stuck()
	send_action(send)

func send_action(send : bool):
	if not send:
		return

	var key = card.active_action.key
	emit_signal('sent', key)


# Must be overridden by a subclass. (see "res://scripts/_player_ai.gd", "res://scripts/_player_local.gd")
func perform_special_action(action_key : String, _extra_args = null):
	push_warning(self, 'can not perform special action ', action_key)
	emit_signal.call_deferred('finished')

func cant_place():
	avatar.thinking = false
	#emit_signal('finished')

func on_avatar_finished():
	if stuck:
		emit_signal('finished')
		emit_signal('card_finished')



# Useful for debugging purposes
func _to_string():
	return {
		Global.AVATARS.RED : 'Red Lightning',
		Global.AVATARS.YELLOW: 'Smiley',
		Global.AVATARS.BLACK: 'Black Diamond',
		Global.AVATARS.WHITE: 'The King',
		Global.AVATARS.BOT: 'Bot'
	}.get(theme, '')
