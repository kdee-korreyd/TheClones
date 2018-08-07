extends KinematicBody2D

const MIN_WALK_SPEED = 10
const MAX_WALK_SPEED = 800
const STOP_FORCE = 1000
const JUMP_SPEED = 600
const JUMP_MAX_AIRBORNE_TIME = 0.35

export (float) var gravity
export (float) var walk_force
var velocity = Vector2()

var on_air_time = 100
var jumping = false
var can_jump = false
var prev_jump_pressed = false
var animation_state = "idle"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	self.velocity = Vector2(0,0)

func _physics_process(delta):
	var force = Vector2(0,self.gravity)
	var jump = Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_jump")
	
	var walk_dir = 0
	if Input.is_action_pressed("ui_left") and self.velocity.x <= MIN_WALK_SPEED:
		walk_dir = -1
		if not animation_state == "jump": #dont let mario turn while jumping
			$"mario-normal-small".flip_h = true
	elif Input.is_action_pressed("ui_right") and self.velocity.x >= -MIN_WALK_SPEED:
		walk_dir = 1
		if not animation_state == "jump":
			$"mario-normal-small".flip_h = false
		
	if walk_dir and abs(self.velocity.x) < MAX_WALK_SPEED:
		force.x += walk_dir * walk_force
	else:
		var vel_sign = sign(self.velocity.x)  #get sign (+ or -)
		var vel_length = abs(self.velocity.x) #get length of vector in x direction (absolute value)
		vel_length -= STOP_FORCE * delta      #apply stop force (in relation to  how much time has passed since last frame)
		if vel_length < 0:
			vel_length = 0
		self.velocity.x = vel_sign * vel_length #set new length (re-apply sign)
		
	if self.velocity.x == 0 and self.velocity.y == 0:
		if not animation_state == "idle":
			$"mario-normal-small/AnimationPlayer".play("idle")
			animation_state = "idle"
	elif self.velocity.x:
		if not animation_state == "run" and not animation_state == "jump":
			$"mario-normal-small/AnimationPlayer".play("run")
			animation_state = "run"
		
		
	#if jump released while in air then dont allow jump until they land
	if prev_jump_pressed and not jump:
		can_jump = false
		
	if is_on_floor():
		#if not can_jump:
		#	$"mario-normal-small/AnimationPlayer".stop()
		on_air_time = 0
		can_jump = true
		if animation_state == "jump":
			animation_state = "idle"
		
	if velocity.y > 0:
		if jumping:
			print (str(self.position.y))
			# If falling, no longer jumping
			jumping = false
		if not is_on_floor():
			can_jump = false   #dont allow jumping if falling 
	
	if on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and can_jump: # and not prev_jump_pressed and not jumping:
		# Jump must also be allowed to happen if the character left the floor a little bit ago.
		# Makes controls more snappy.
		#velocity.y = -JUMP_SPEED
		if not prev_jump_pressed:
			#if button just pressed then apply jump force
			force.y -= (self.gravity * 15 + (abs(self.velocity.x)/MAX_WALK_SPEED*1000))  #jump higher with momentum
			$"mario-normal-small/AnimationPlayer".play("jump")
			animation_state = "jump"
			jumping = true
		else:
			if not is_on_floor():
				force.y -= self.gravity
			else:
				can_jump = false  #landed, done jumping (also keeps us from wile coyote-ing)
		
	
	on_air_time += delta
	prev_jump_pressed = jump
	
	self.velocity += force * delta
	self.velocity = move_and_slide(self.velocity,Vector2(0,-1))
	
	if animation_state == "run":
		$"mario-normal-small/AnimationPlayer".playback_speed = abs(self.velocity.x)/MAX_WALK_SPEED * 4
	