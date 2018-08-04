extends Area2D
signal hit

# class member variables go here, for example:
export (int) var speed
var screensize

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	screensize = get_viewport_rect().size
	self.hide()

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	var velocity = Vector2()
	$AnimatedSprite.animation = "right"
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.animation = "up"
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
		$AnimatedSprite.flip_v = true
		$AnimatedSprite.animation = "up"
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		$AnimatedSprite.flip_h = true
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		$AnimatedSprite.flip_h = false
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		get_node("AnimatedSprite").play()
		#$AnimatedSprite.play() #same as get_node("AnimatedSprite") (note: $ & get_node are relative to this node)
	else:
		$AnimatedSprite.stop()
	
	#use self (not 'this')	
	self.position += velocity * delta
	self.position.x =  clamp(self.position.x, 0, screensize.x)
	self.position.y =  clamp(self.position.y, 0, screensize.y)


func _on_Player_body_entered(body):
	self.hide()
	self.emit_signal("hit")
	$CollisionShape2D.disabled = true
	
func start(pos):
	self.position = pos
	self.show()
	$CollisionShape2D.disabled = false
