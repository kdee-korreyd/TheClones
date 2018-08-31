extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export (float) var gravity
export (float) var walk_force
var velocity = Vector2()
var walk_dir = -1
var go = false
var disable_movement = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	#can update groups here: doing it through the gui now THOUGH this would be better for inheritance
	# scenes DO NOT inherit groups through GUI
	#add_to_group("enemies")
	if walk_dir < 0:
		self.get_node("Sprite").flip_h = true
	else:
		self.get_node("Sprite").flip_h = false

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func do_disable_movement():
	self.disable_movement = true
	
func do_enable_movement():
	self.disable_movement = false

#called in physics process before doing anything
# overwrite this in child classes to do different physics process stuff
# return true to continue with base class's (this) physics process
# return false to immediately return from physics process (skipping base class's)
#			note: returning false: will still call post_physics_process
func pre_physics_process(delta):
	return true

#called in physics process after doing stuff
# overwrite this in child class to do stuff at the end of physics process (end = after base class's stuff)
# return true to continue with base class's (this) (nothing at the moment)
# return false to immeditaly return from physics process
func post_physics_process(delta):
	return true
	
#base classes actually physics process work
# put here so that child classes may call base class's physics process
# without worrying about doubling up on _physics_process calls
#note about _physics_process:
#	the _physics_prcess method WILL get called twice if parent class also has it defined
#	you dont actually need to parent .call it or anything (godot finds all _physics_process references it seems)
#   this is why we have a do_physics_process class
func do_physics_process(delta):
	if self.go:
		var force = Vector2(0,self.gravity)
	
		if walk_dir:
			self.velocity.x = walk_dir * self.walk_force
			
		self.velocity += force * delta
		self.velocity = move_and_slide(self.velocity,Vector2(0,-1))


#do collision stuff for _physics_process
func do_collisions(delta):
	if self.is_on_wall():
		walk_dir *= -1
			
	if walk_dir < 0:
		self.get_node("Sprite").flip_h = true
	else:
		self.get_node("Sprite").flip_h = false
		
	self.do_hits()


#check if I hit stuff
func do_hits():
	for i in range(get_slide_count()):
		var c = get_slide_collision(i)
		if c.collider and c.collider.is_in_group("players"):
			if c.normal.y != 1 and sign(c.normal.x) != sign(self.velocity.x):
				print("enemy hit mario")
				print(c.normal)
				#if not being jumped on then do something
				c.collider._on_hit(self)
	
#IMPORTANT note about _physics_process:
#	the _physics_prcess method WILL get called twice if parent class also has it defined
#	you dont actually need to parent .call it or anything (godot finds all _physics_process references it seems)
#   this is why we have a do_physics_process class
func _physics_process(delta):
	if !self.disable_movement:
		if pre_physics_process(delta):
			do_physics_process(delta)
			do_collisions(delta)
		if post_physics_process(delta):
			pass
	
			
func _on_stomped(stomper):
	self.get_node("squish").play()
	if self.get_node("Sprite/AnimationPlayer").has_animation("die"):
		self.get_node("Sprite/AnimationPlayer").play("die")
	self.walk_dir = 0
	self.velocity.x = 0
	stomper.add_collision_exception_with(self) #no double stomps
	
func _on_shot():
	self.get_node("shot").play()
	self.get_node("Sprite").flip_v = true
	self.get_node("CollisionShape2D").disabled = true
	self.walk_dir = 0
	self.velocity = Vector2(0,-1000)
	
func _on_kicked(kicker):
	pass
	
func _kill_me(anim_name):
	if anim_name == "die":
		self.queue_free()

func _can_kick():
	return false

#dont move until in viewport
func _on_VisibilityNotifier2D_viewport_entered(viewport):
	print("something entered marios Viewport!")
	self.go = true
