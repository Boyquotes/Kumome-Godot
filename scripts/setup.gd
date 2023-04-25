extends SwapScene
# BEAR = 5, CHICKEN = 6, ELEPHANT = 7, OWL = 8, RHINO = 9, SNAKE = 10, MONKEY = 11
var data := [
	{
		'name': 'Bert',
		'frame' : 0,
		'spirit': 3,
		'bg': Color('#cdd6eb'),
		'avatar': Global.AVATARS.BEAR
	},
	{
		'name': 'Nubia',
		'frame': 1,
		'spirit': 0,
		'bg': Color('#eedbb7'),
		'avatar': Global.AVATARS.SNAKE
	},
	{
		'name': '大肌肉',
		'frame': 2,
		'spirit': 1,
		'bg': Color('#bdddb6'),
		'avatar': Global.AVATARS.CHICKEN
	},
	{
		'name': 'Saidi',
		'frame': 3,
		'spirit': 2,
		'bg': Color('#e8c4c4'),
		'avatar': Global.AVATARS.ELEPHANT
	}
]

var location_data := {
	'spirits_show' : [],
	'spirits_hide' : [],

}

var active_character := 0
var transitioning := false

func _ready():
	setup()
	show_active_avatar(-1)
	emit_signal("changed_quit_to", preload("res://scenes/title.tscn"))

func setup():
	for sa in $spirit_animals.get_children():
		location_data.spirits_show.append(sa.position)
		sa.position = sa.position + 700*Vector2.ONE*Vector2(sign(sa.position.x), 1.0)
		location_data.spirits_hide.append(sa.position)

	location_data['bust'] = $bust.position
	location_data['dummy_dist'] = abs($bust.position.x - $dummy.position.x)
	$bust.position.x -= location_data['dummy_dist']
	$dummy.position.y = $bust.position.y


func show_active_avatar(dir : float):
	transitioning = true
	dir = sign(dir)
	var dur := 0.5
	var info = data[active_character]

	$dummy.frame = $bust.frame
	$bust.frame = info.frame
	$dummy.position = $bust.position
	$bust.position = location_data.bust - dir * location_data.dummy_dist * Vector2.RIGHT
	$name_label.text = ''


	var bust_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	bust_tween.tween_property($dummy, 'position', location_data.bust + dir * location_data.dummy_dist * Vector2.RIGHT, dur)
	bust_tween.tween_property($bust, 'position', location_data.bust, dur)
	bust_tween.tween_property($bg, 'color', info.bg, dur)
	bust_tween.connect('finished', $name_label.set.bind('text', info.name))
	bust_tween.connect('finished', $players/player.set.bind('player_name', info.name))
	bust_tween.connect('finished', set.bind('transitioning', false))


	for i in $spirit_animals.get_child_count():
		var sa = $spirit_animals.get_child(i)
		var spirit_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		(spirit_tween.tween_property(sa, 'position', location_data.spirits_hide[i], dur/2)
			.set_ease(Tween.EASE_IN)
			.set_delay(0.1*(i%3))
		)
		spirit_tween.tween_callback(sa.set.bind('frame', info.spirit))
		(spirit_tween.tween_property(sa, 'position', location_data.spirits_show[i], dur/2)
			.set_ease(Tween.EASE_OUT)
		)

func go_to_next_bust(dir : int):
	if transitioning: return

	active_character = posmod(active_character + dir, len(data))
	show_active_avatar(dir)

func _on_right_pressed():
	go_to_next_bust(1)


func _on_left_pressed():
	go_to_next_bust(-1)

func _on_continue_pressed():
	goto(Vector2(400, 1700*1.5))


func _on_play_pressed():
	var players := []
	for pl in $players.get_children():
		var info = pl.get_data()
		if info.nature:
			players.append([
				info.nature,
				data[active_character].avatar if info.player else Global.AVATARS.RANDOM,
				info.team
			])

	#Array[B/L : String, avatar_id : AVATARS, team : int]
	Global.adjust_setting('playing_with_cards', $with_cards.selected == 1)
	var board = Global.generate_standard_board(players)
	emit_signal('generated_level', board)
	emit_signal("swapped_to", preload("res://scenes/play.tscn"))
