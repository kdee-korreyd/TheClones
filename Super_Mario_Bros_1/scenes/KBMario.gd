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
var can_pipe = false
var prev_jump_pressed = false
var animation_state = "idle"
var is_skidding = false
var is_dead = false
var max_move_speed = MAX_WALK_SPEED
var viewport_left_threshold
var can_hit_stuff  #true if self can hit stuff (used by other objects mostly at this time)
var state_obj = {}
var switching_avatars = false
var is_big = false
var is_fire = false
var is_star = false
var is_transitioning = false
var is_shrinking = false
var is_anchored = false

var disable_controls = false
var disable_movement = false

#this is here to do things like copying small marios data to big mario
# during transition (helps maintian velocities n such).  still not great because the new marios _ready gets called
# when new mario is added to a scene so this ends up having to run after the _ready
# which blows away some of the initializations (we can do better but this works for now)
func clone_me(new_obj):
	new_obj.gravity = gravity
	new_obj.walk_force = walk_force
	new_obj.velocity = Vector2(velocity.x,velocity.y)
	new_obj.on_air_time = on_air_time
	new_obj.jumping = jumping
	new_obj.can_jump = can_jump
	new_obj.prev_jump_pressed = prev_jump_pressed
	new_obj.animation_state = animation_state
	new_obj.is_skidding = is_skidding
	new_obj.is_dead = is_dead
	new_obj.max_move_speed = max_move_speed
	new_obj.viewport_left_threshold = viewport_left_threshold
	new_obj.can_hit_stuff = can_hit_stuff
	new_obj.switching_avatars = switching_avatars
	new_obj.is_fire = is_fire
	new_obj.is_transitioning = is_transitioning
	new_obj.is_shrinking = is_shrinking
	new_obj.disable_controls = disable_controls
	new_obj.disable_movement = disable_movement

#Note: i have some magic vars/nodes (can_hit_stuff & BreakRayCast2D) which outside objects(nodes)
#		use to tell if theyve been hit by me (and to avoid double hitting and things like that).
#		It is probably more efficient and less "magical" if I tell the other objects
#		that I hit them instead.  Also less error prone, because if someone else wants
#		to hit those objects, they too would need both "magic" vars/nodes.

func _ready():
	print("callng MarioSmall ready")
	is_big = false
	# Called when the node is added to the scene for the first time.
	# Initialization here
	self.velocity = Vector2(0,0)
	#math:
	#so the drag_margin percentage is actually the percentage from the center of the viewport (not of the full width)
	# this should update whenever the screen size changes actuall (too lazy to do it now)
	var viewport_x_half = get_viewport_rect().size.x/2
	#viewport_left_threshold = viewport_x_half + (viewport_x_half * $Camera2D.drag_margin_right) + 50
	print("REsetting viewport left threshold")
	#print(state_obj.has('is_ducking'))
	var pups = get_tree().get_nodes_in_group("powerups")
	# this works: but was not actually what i wanted to do
	#for pup_node in pups:
	#	pup_node.get_node("Area2D").connect("body_entered",self,"_on_powerup")
	#	print(pup_node.name)
	#$"mario-normal-small".material.set_shader_param("go",1) #start star shader

	
func _process(delta):
	#dont let camera drag left (mario 1 doesnt allow backtracking)
	#print(get_viewport().size.x)
	#print($Camera2D.position)
	#print($Camera2D.global_position)
	#print(self.get_viewport().get_visible_rect())
	
	# move global camera position
	#if $Camera2D.global_position.x - self.viewport_left_threshold > $Camera2D.limit_left:
	#	$Camera2D.limit_left = $Camera2D.global_position.x  - self.viewport_left_threshold
	if self.is_transitioning and !$"mario-normal-small/AnimationPlayer".is_playing():
		#done transitioning
		self.disable_controls = false
		self.disable_movement = false
		self.is_transitioning = false
		print("done transitioning")
		get_tree().call_group("enemies", "do_enable_movement")
		
		if self.is_shrinking:
			var small_mario = load("res://scenes/KBMario.tscn").instance()
			var my_shape_bottom = $CollisionShape2D.shape.extents.y + $CollisionShape2D.position.y
			var other_mario_shape_bottom = small_mario.get_node("CollisionShape2D").shape.extents.y + small_mario.get_node("CollisionShape2D").position.y
			var y_offset = my_shape_bottom - other_mario_shape_bottom
			print("moving mario " + str(y_offset))
			get_node("/root").get_child(0).get_node("MarioCam").add_child(small_mario)
			small_mario.global_transform = self.get_global_transform().translated(Vector2(0,y_offset))
			self.switching_avatars = true
			self.queue_free()
	if self.is_star and $StarTimer.is_stopped():
		#manually checking timer instead of using event
		self.is_star = false
		$"mario-normal-small".material.set_shader_param("go",0) #stop star shader
		get_node("/root").get_child(0).get_node("Music").play()
		get_node("/root").get_child(0).get_node("StarMusic").stop()
	
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
	if self.is_anchored:
		return
		
	var force = Vector2(0,self.gravity)
	
	if not disable_controls:
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
		#no walking if ducking
		if state_obj.has('is_ducking') and state_obj.is_ducking and is_on_floor():
			walk_dir = 0
			
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
		
				
		#Kill Stuff!!!
		for i in range(get_slide_count()):
			var c = get_slide_collision(i)
			if c.collider and c.collider.is_in_group("enemies"):
				print("mario is colliding with " + c.collider.name)
				print(c.normal)
				if self.is_star:
					c.collider._on_shot()
					self.add_collision_exception_with(c.collider)
					#force += c.remainder #trying to not slow down if hit something with star
				elif c.normal.y == -1:
					#c.collider.queue_free()  #this guy is done for
					c.collider._on_stomped(self)
					#self.add_collision_exception_with(c.collider) #no more colliding with this guy (now doing this in enemy scene - some enemies can still be hit after this)
					force.y -= (self.gravity * 15 + (abs(self.velocity.x)/MAX_RUN_SPEED*1000))  #jump higher with momentum
					on_air_time = 0
					jumping = true #bounce
					can_jump = true
					prev_jump_pressed = true #allow gravity negation
					$"mario-normal-small/AnimationPlayer".play("jump")
					animation_state = "jump"
				elif c.normal.y == 0 and c.normal.x != 0:
					if c.collider.has_method("can_kick") and c.collider.can_kick():
						c.collider._on_kicked(self)
					else:
						#mario was hit
						# actuall not good enough to tell if mario was hit because only checks if mario bumped in to something
						# but not if something bumped in to mario
						self._on_hit(c.collider)
			if c.collider and c.collider.is_in_group("powerups"):
				pass
		
	if !self.disable_movement:
		self.velocity += force * delta
		var orig_velocity = self.velocity
		self.velocity = move_and_slide(self.velocity,Vector2(0,-1))
		if self.is_star:
			#hacky/inefficient way to do this (will cause problems most likely.. but not worried about perfection on this project)
			for i in range(get_slide_count()):
				var c = get_slide_collision(i)
				if c.collider and c.collider.is_in_group("enemies"):
					self.velocity = orig_velocity
		
	
	if animation_state == "run":
		$"mario-normal-small/AnimationPlayer".playback_speed = abs(self.velocity.x)/MAX_RUN_SPEED * 4
	else:
		$"mario-normal-small/AnimationPlayer".playback_speed = 1
		
			
	#test if cast is colliding	
	#if $BreakRayCast2D.is_colliding():
	#	print($BreakRayCast2D.get_collider())
	

#something hit me
func _on_hit(body):
	print("player was hit by " + body.name)
	if self.is_star:
		#enemies also should die if they hit mario while star is enabled
		body._on_shot()
		self.add_collision_exception_with(body)
	else:	
		if self.is_big:
			self.shrink()
		else:
			self._on_die()

func _on_die():
	if !self.is_dead:
		$"mario-normal-small/AnimationPlayer".play("die")
		#self.velocity = Vector2(0,-self.gravity/2.5)
		$CollisionShape2D.disabled = true
		get_node("/root").get_child(0).get_node("Music").stop()
		get_node("/root").get_child(0).get_node("StarMusic").stop()
		$FxDie.play()
		self.disable_controls = true
		self.is_dead = true
		$DieTimer.start()
		self.disable_movement = true
		
func _on_die_timer_end():
	self.velocity = Vector2(0,-self.gravity/2.5)
	self.disable_movement = false

func _on_Visibility_viewport_exited(viewport):
	if not self.switching_avatars:
		self._on_die()
	
	

func _on_powerup(item):
	print("powerup")
	print(item.name)
	if item.PowerUpType == "mushroom":
		if !self.is_big:
			#this kind of works
			print("got mushroom")
			var big_mario = load("res://scenes/KBMarioBig.tscn").instance()
			
			#if mario heights are different we don't want big mario to spawn in the floor so offset so that his feet
			# are in the same spot that little marios feet would have been
			var my_shape_bottom = $CollisionShape2D.shape.extents.y + $CollisionShape2D.position.y
			var other_mario_shape_bottom = big_mario.get_node("CollisionShape2D").shape.extents.y + big_mario.get_node("CollisionShape2D").position.y
			var y_offset = my_shape_bottom - other_mario_shape_bottom
			print("moving mario " + str(y_offset))
			
			#disable movement because 1) thats how the real mario does it and 2) gravity can put us back into the ground before switching
			#big_mario.disable_controls = true
			#big_mario.disable_movement = true
			
			#get_node("/root").get_child(0).add_child(big_mario)
			get_node("/root").get_child(0).get_node("MarioCam").add_child(big_mario)
			big_mario.global_transform = self.get_global_transform().translated(Vector2(0,y_offset))
			self.clone_me(big_mario)
			big_mario.grow()
			self.switching_avatars = true
			
			print(self.global_position)
			print(big_mario.global_position)
			
			#would be better to just copy the camera over if thats possible
			#var cam = $Camera2D.duplicate()
			#big_mario.add_child($Camera2D.duplicate())
			#cam.make_current()
			#var cam = get_node("/root").get_child(0).get_node("MarioCam").get_node("KBMario/Camera2D2")
			#print(cam.position)
			#get_node("/root").get_child(0).get_node("MarioCam").get_node("KBMario").remove_child(cam)
			#big_mario.add_child(cam)
			#cam.owner = big_mario
			#cam.make_current()
			#print(cam.position)
			#print(cam)
			
			self.queue_free()
			item._on_grabbed()
			print(big_mario)
	elif item.PowerUpType == "fireflower":
		if !self.is_big or !self.is_fire:
			#this kind of works
			print("got fire flower")
			var flower_mario = load("res://scenes/KBMarioFireFlower.tscn").instance()
			
			var my_shape_bottom = $CollisionShape2D.shape.extents.y + $CollisionShape2D.position.y
			var other_mario_shape_bottom = flower_mario.get_node("CollisionShape2D").shape.extents.y + flower_mario.get_node("CollisionShape2D").position.y
			var y_offset = -abs(other_mario_shape_bottom - my_shape_bottom)
			print("moving mario " + str(y_offset))
			
			get_node("/root").get_child(0).get_node("MarioCam").add_child(flower_mario)
			flower_mario.grow()
			flower_mario.global_transform = self.get_global_transform().translated(Vector2(0,y_offset))
			self.switching_avatars = true
			
			self.queue_free()
			print(flower_mario)
			item._on_grabbed()
		else:
			pass
	elif item.PowerUpType == "star":
		self.is_star = true
		$"mario-normal-small".material.set_shader_param("go",1) #start star shader
		$StarTimer.start()
		item._on_grabbed()
		get_node("/root").get_child(0).get_node("Music").stop()
		get_node("/root").get_child(0).get_node("StarMusic").play(0.8)

