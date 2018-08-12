extends KinematicBody2D

const MIN_WALK_SPEED = 10
const MAX_WALK_SPEED = 400
const MAX_RUN_SPEED = 800
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
var is_skidding = false
var max_move_speed = MAX_WALK_SPEED
var viewport_left_threshold
var can_hit_stuff  #true if self can hit stuff (used by other objects mostly at this time)
var state_obj = {}
var switching_avatars = false

#Note: i have some magic vars/nodes (can_hit_stuff & BreakRayCast2D) which outside objects(nodes)
#		use to tell if theyve been hit by me (and to avoid double hitting and things like that).
#		It is probably more efficient and less "magical" if I tell the other objects
#		that I hit them instead.  Also less error prone, because if someone else wants
#		to hit those objects, they too would need both "magic" vars/nodes.

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	self.velocity = Vector2(0,0)
	#math:
	#so the drag_margin percentage is actually the percentage from the center of the viewport (not of the full width)
	# this should update whenever the screen size changes actuall (too lazy to do it now)
	var viewport_x_half = get_viewport_rect().size.x/2
	viewport_left_threshold = viewport_x_half + (viewport_x_half * $Camera2D.drag_margin_right) + 50
	print("REsetting viewport left threshold")
	
func _process(delta):
	#dont let camera drag left (mario 1 doesnt allow backtracking)
	#print(get_viewport().size.x)
	#print($Camera2D.position)
	#print($Camera2D.global_position)
	#print(self.get_viewport().get_visible_rect())
	
	# move global camera position
	#if $Camera2D.global_position.x - self.viewport_left_threshold > $Camera2D.limit_left:
	#	$Camera2D.limit_left = $Camera2D.global_position.x  - self.viewport_left_threshold
	pass
	
func flipmeH(flip_h):
	$"mario-normal-small".flip_h = flip_h
	#break_cast_sign = sign($BreakRayCast2D.position.x)
	if flip_h:
		$BreakRayCast2D.position.x = -abs($BreakRayCast2D.position.x) 
	else:
		$BreakRayCast2D.position.x = abs($BreakRayCast2D.position.x) 
		
func custom_controls(delta):
	pass
	
func custom_animations(delta):
	pass

func _physics_process(delta):
	var force = Vector2(0,self.gravity)
	var jump = Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_jump")
	
	#WALKING -----------------------------------------------
	if Input.is_action_pressed("ui_x"):
		self.max_move_speed = MAX_RUN_SPEED
	else:
		self.max_move_speed = MAX_WALK_SPEED
		
	var walk_dir = 0
	if Input.is_action_pressed("ui_left") and self.velocity.x <= MIN_WALK_SPEED:
		walk_dir = -1
		if not animation_state == "jump": #dont let mario turn while jumping
			#$"mario-normal-small".flip_h = true
			flipmeH(true)
	elif Input.is_action_pressed("ui_right") and self.velocity.x >= -MIN_WALK_SPEED:
		walk_dir = 1
		if not animation_state == "jump":
			#$"mario-normal-small".flip_h = false
			flipmeH(false)
	self.custom_controls(delta)
		
	if walk_dir and abs(self.velocity.x) < max_move_speed:
		force.x += walk_dir * walk_force
		is_skidding = false
	else:
		var vel_sign = sign(self.velocity.x)  #get sign (+ or -)
		var vel_length = abs(self.velocity.x) #get length of vector in x direction (absolute value)
		vel_length -= STOP_FORCE * delta      #apply stop force (in relation to  how much time has passed since last frame)
		if vel_length < 0:
			vel_length = 0
		self.velocity.x = vel_sign * vel_length #set new length (re-apply sign)
		if vel_length and self.is_on_floor():
			if self.velocity.x > 0 and Input.is_action_pressed("ui_left"):
				is_skidding = true
			elif self.velocity.x < 0 and Input.is_action_pressed("ui_right"):
				is_skidding = true
		else:
			is_skidding = false
	#END MOVING ---------------------------------------------
		
	#ANIMATIONS & SOUND -------------------------------------
	if self.velocity.x == 0 and self.velocity.y == 0:
		if not animation_state == "idle":
			$"mario-normal-small/AnimationPlayer".play("idle")
			animation_state = "idle"
	elif self.velocity.x:
		if not animation_state == "run" and not animation_state == "jump":
			$"mario-normal-small/AnimationPlayer".play("run")
			animation_state = "run"
	
	#skid animation
	if self.is_skidding:
		if not self.animation_state == "skid":
			$"mario-normal-small/AnimationPlayer".play("skid")
			self.animation_state = "skid"
			if self.velocity.x > 0:
				#$"mario-normal-small".flip_h = true
				flipmeH(true)
			elif self.velocity.x < 0:
				#$"mario-normal-small".flip_h = false
				flipmeH(false)
		if not $FxSkid.playing:
			$FxSkid.play()
	else:
		#if self.animation_state == "skid":
		#	$"mario-normal-small/AnimationPlayer".stop()
		#	self.animation_state = ""
		if $FxSkid.playing:
			$FxSkid.stop()
	self.custom_animations(delta)
	#END ANIMATIONS -----------------------------------------
		
	#JUMPING -----------------------------------------------
	#if jump released while in air then dont allow jump until they land
	if prev_jump_pressed and not jump:
		can_jump = false
		
	if is_on_floor():
		#if not can_jump:
		#	$"mario-normal-small/AnimationPlayer".stop()
		on_air_time = 0
		can_jump = true
		can_hit_stuff = true
		if animation_state == "jump":
			animation_state = "idle"
		
	if velocity.y > 0:
		if $FxJump.playing:
			$FxJump.stop()
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
			force.y -= (self.gravity * 15 + (abs(self.velocity.x)/MAX_RUN_SPEED*1000))  #jump higher with momentum
			$"mario-normal-small/AnimationPlayer".play("jump")
			animation_state = "jump"
			jumping = true
			$FxJump.play()
		else:
			if not is_on_floor():
				force.y -= self.gravity
			else:
				can_jump = false  #landed, done jumping (also keeps us from wile coyote-ing)
		
	on_air_time += delta
	prev_jump_pressed = jump
	#END JUMPING -----------------------------------------------
	
	self.velocity += force * delta
	self.velocity = move_and_slide(self.velocity,Vector2(0,-1))
	
	if animation_state == "run":
		$"mario-normal-small/AnimationPlayer".playback_speed = abs(self.velocity.x)/MAX_RUN_SPEED * 4
	else:
		$"mario-normal-small/AnimationPlayer".playback_speed = 1
	
	#test if cast is colliding	
	#if $BreakRayCast2D.is_colliding():
	#	print($BreakRayCast2D.get_collider())
	
	
func _on_Visibility_viewport_exited(viewport):
	if not self.switching_avatars:
		get_node("/root").get_child(0).get_node("Music").stop()
		$FxDie.play()
	
	
func _on_Area2D_body_entered(body):
	if self.name == "KBMario":
		#this kind of works
		print("got mushroom")
		var big_mario = load("res://scenes/KBMarioBig.tscn").instance()
		get_node("/root").get_child(0).add_child(big_mario)
		big_mario.grow()
		big_mario.global_position.x = self.global_position.x
		big_mario.global_position.y = self.global_position.y-39
		self.switching_avatars = true
		
		#would be better to just copy the camera over if thats possible
		var cam = $Camera2D.duplicate()
		big_mario.add_child($Camera2D.duplicate())
		cam.make_current()
		
		#big_mario.get_node("Camera2D").limit_left = $Camera2D.limit_left
		#big_mario.get_node("Camera2D").make_current()
		# big_mario.velocity = self.velocity  #mario actually temporarily stops while growing
		self.queue_free()
		print(big_mario)

