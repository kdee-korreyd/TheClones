extends KinematicBody2D

export (String) var PowerUpType
# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var walk_dir = 0
var walk_force = 300
var gravity = 3000
var velocity = Vector2()
var reveal_velocity = 100

var is_revealing = true
var go = false

func _ready():
	self._on_revealed()
	pass

func _physics_process(delta):
	if self.go:
		if self.is_revealing:
			print("test_move")
			var vel = Vector2(0,-self.reveal_velocity)
			
			#move_and_collide will actually keep you from doing manual translations below
			#	auto-sets position if collision occurs
			#var c = move_and_collide(vel)
			
			#test_move doesn't work fully - looks like test_move only tests from the transfrom POINT (doesnt take shape into account)
			#var c = test_move(self.get_global_transform(),vel*delta) 
			
			#alternate way (with query) #this works because it takes a shape into account
			#BIG NOTE: IMPORTANT: intersect_shape query ONLY sees things that are on layers.
			#		eg. it doesnt matter that (this) shape is on a layer and the other object is on the layers mask
			#			it will NOT see the other object unless it is on some layer.
			#			in fact i'd assume that the layer of the shape I am stealing from doesnt realy matter at all
			#			if no layer specified in query then it just checks ALL layers. and if a layer
			#			is specified it probably just checks that layer (though i havnt tested specifying a layer)
			var space_state = get_world_2d().direct_space_state
			var query = Physics2DShapeQueryParameters.new()
			query.set_shape($Area2D/CollisionShape2D.shape)
			query.transform = self.global_transform.translated(vel*delta)
			query.exclude = [self] + self.get_children()
			#query.collision_layer = 4
			#print(self.get_child_count())
			var c = space_state.intersect_shape(query)
			##
			
			print(c)
			if c:
				self.global_translate(vel*delta)
			else:
				is_revealing = false #done with reveal
		else:
			var force = Vector2(0,self.gravity)
		
			if walk_dir:
				self.velocity.x = walk_dir * self.walk_force
				
			self.velocity += force * delta
			self.velocity = move_and_slide(self.velocity,Vector2(0,-1))
			
			if ( self.is_on_wall() ):
				walk_dir *= -1

func kill_me():
	self.queue_free()
			
func _on_revealed():
	self.go = true
	self.is_revealing = true
	$AudioItemReveal.play()
	
func _on_grabbed():
	self.kill_me()

func _on_Area2D_body_entered(body):
	body._on_powerup(self)
	self._on_grabbed()
	pass # replace with function body
