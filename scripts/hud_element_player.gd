extends TextureRect

var player : Player

func _process(_delta):
	for i in $stars.get_child_count():
		$stars.get_child(i).visible = i < Global.settings.special_cards_per_game - player.special_cards_count
	$stuck.visible = player.stuck
	$stars.visible = not player.stuck

func attach_player(pl : Player):
	player = pl
	texture = player.avatar.texture

func _ready():
	await get_tree().create_timer(0.5).timeout
