extends Node2D

# class member variables go here, for example:
var screen_size
var pad_size
var direction = Vector2(1.0, 0.0)

const INITIAL_BALL_SPEED = 80
var ball_speed = INITIAL_BALL_SPEED
const PAD_SPEED = 150

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	screen_size = get_viewport_rect().size
	pad_size = get_node("left").get_texture().get_size()
	set_process(true)

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	var ball_pos = get_node("ball").position
	var left_rect = Rect2(get_node("left").position - pad_size*0.5, pad_size)
	var right_rect = Rect2(get_node("right").position - pad_size*0.5, pad_size)
	
	ball_pos += direction * ball_speed * delta
	if ((ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > screen_size.y && direction.y > 0)):
		direction.y = -direction.y

	if ((left_rect.has_point(ball_pos) and direction.x < 0) or (right_rect.has_point(ball_pos) and direction.x > 0)):
		direction.x = -direction.x
		ball_speed *= 1.1
		direction.y = randf()*2.0-1
		direction = direction.normalized()
		
	if (ball_pos.x < 0 or ball_pos.x > screen_size.x):
		ball_pos = screen_size*0.5
		ball_speed = INITIAL_BALL_SPEED
		direction = Vector2(-1,0)
		
	get_node("ball").position = ball_pos
	
	var moves = {"move_up":-1,"move_down":1}
	var players = {}
	players["left"] = get_node("left").position
	players["right"] = get_node("right").position

	for move in moves:
		for player in players:
			var move_dir = player + "_" + move
			if Input.is_action_pressed(move_dir):
				players[player].y += moves[move] * PAD_SPEED * delta
				if players[player].y < 0: players[player].y = 0
				elif players[player].y > screen_size.y: players[player].y = screen_size.y
				
	get_node("left").position = players["left"]
	get_node("right").position = players["right"]