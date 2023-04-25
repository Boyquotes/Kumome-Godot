############################ LEVEL CODES ############################
	# Level codes are made up of a header and a body, seperated by a single hyphen:
	#
	# 	[header]
	#	-
	#	[body]

	##### HEADER #####
		# Each line of the header represents a player and is of the form:
		#
		#	flavor color team
		#
		# The flavor is one of [L, B, R] and indicates whether the player is to be controlled
		# locally, by ai, or remotely (not implemented).
		#
		# The color is an int, and indicates which avatar to use. See Global.AVATARS
		#
		# The team is an int, and indicates which team the player belongs to.

	##### BODY #####
		# The body represents the game board. Each line of the body is a row of the board.
		# Each character of the body is one one of the following:
		#	. (an empty square)
		#	x (a mined square)
		#	0 (the player defined by line 0 of the header)
		#	1 (the player defined by line 1 of the header)
		#	2 (the player defined by line 2 of the header)
		#	... etc.

	##### EXAMPLE #####
		# Consider the level code:
		#
		# L 0 0
		# B -1 1
		# -
		# 0...
		# .xx.
		# .xx.
		# ...1
		#
		# This defines a 4 by 4 board in which the a local player on team 0 and
		# color 0 starts in the  top-left corner of the board, the ai controlled
		# player on team 1 with a random color starts on the bottom right corner.
