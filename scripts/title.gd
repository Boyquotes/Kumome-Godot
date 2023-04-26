extends SwapScene

func _ready():
	for button in $buttons.get_children():
		button.visible = false

	#play_buttons()
	play_intro()
	play_rules()

	$username.text = Global.active_user.get('username', '')

func play_intro():

	var tween := create_tween().set_parallel()
	for i in $title.get_child_count():
		var letter = $title.get_child(i)
		(tween.tween_property(letter, 'position', letter.position, 0.7)
			.set_delay(0.1*i)
			.set_trans(Tween.TRANS_BOUNCE)
			.set_ease(Tween.EASE_OUT)
		)
		letter.position.y = -600
	(tween.tween_property($title_line, 'size:x', 900.0, 0.5)
		.set_delay(1.2)
		.set_trans(Tween.TRANS_CUBIC)
		.set_ease(Tween.EASE_IN_OUT)
	)
	$title_line.size.x = 0

	tween.connect('finished', play_buttons)

func play_buttons():
	var tween := create_tween().set_parallel()
	for i in $buttons.get_child_count():
		var button = $buttons.get_child(i)
		(tween.tween_property(button, 'position', button.position, 0.5)
			.set_delay(0.4 + 0.1 * i)
			.set_trans(Tween.TRANS_CUBIC)
			.set_ease(Tween.EASE_OUT)
		)
		button.position.x = 800 if i % 2 else -button.size.x
		button.visible = true

func play_rules():
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($how_to/title, 'rotation', 0.0, 0.9)
	tween.tween_property($how_to/title, 'rotation', PI/24, 0.9)


func goto_how_to():
	goto(Vector2(-400, 850))

func goto_title():
	goto(Vector2(400, 850))

func goto_credits():
	goto(Vector2(1200, 850))

func goto_play():
	goto(Vector2(400, -850), emit_signal.bind('swapped_to', preload("res://scenes/setup.tscn")))

func goto_puzzle_editor():
	goto(Vector2(400, -850), emit_signal.bind('swapped_to', preload("res://scenes/puzzle_editor.tscn")))

func _on_play_pressed():
	goto_play()


func _on_how_to_pressed():
	goto_how_to()


func _on_settings_pressed():
	emit_signal('opened_settings')


func _on_credits_pressed():
	goto_credits()


func _on_got_it_pressed():
	goto_title()


func _on_puzzles_pressed():
	goto_puzzle_editor()
