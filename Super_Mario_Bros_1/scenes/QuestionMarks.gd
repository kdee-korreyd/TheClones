extends StaticBody2D
 
export (PackedScene) var BrickCoinParticles
export (PackedScene) var GrowMushroom
export (PackedScene) var FireFlower
export (PackedScene) var Star
export (String) var ContentType

var hit_last_frame = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	# $Particles2D.speed_scale = 4
	print(get_node("/root").get_child(0).name) #<-- gets root node (assigned in Project)
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	var hit = false
	var space_state = get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	query.set_shape($CollisionShape2D.shape)
	query.transform = self.global_transform.translated(Vector2(0,0.1))
	#query.transform = self.transform
	query.exclude = [self]
	#query.collision_layer = self.collision_layer
	var hits = space_state.intersect_shape(query)
	
	for h in hits:
		#should use groups for this check instead
		if h.collider.has_node("BreakRayCast2D"):
			hit = true
			if not hit_last_frame: 
				# only do hit stuff if hitters cast is not hit anything else
				#  or if hitters cast is hitting self
				var do_hit = true
				if h.collider.get_node("BreakRayCast2D").is_colliding() and h.collider.get_node("BreakRayCast2D").get_collider() != self:
					do_hit = false
					
				if do_hit and h.collider.can_hit_stuff:
					print("test2X" + str(h.collider.can_hit_stuff))
					if $QuestionMarkSprite/AnimationPlayer.assigned_animation != "hit":
						h.collider.can_hit_stuff = false
						print("test2" + str(h.collider.can_hit_stuff))
						if self.ContentType == "coin":
							var coin = BrickCoinParticles.instance()
							self.add_child(coin)
							coin.emitting = true
							coin.get_node("Hit").play()
						elif self.ContentType == "growmushroom":
							var mushroom = GrowMushroom.instance()
							#get_node("/root").get_child(0).add_child(mushroom)
							get_node("/root").get_child(0).get_node("Layer1").add_child(mushroom)
							mushroom.global_transform = mushroom.global_transform.translated(self.global_position)
						elif self.ContentType == "fireflower":
							var flower = FireFlower.instance()
							get_node("/root").get_child(0).get_node("Layer1").add_child(flower)
							flower.global_transform = flower.global_transform.translated(self.global_position)
						elif self.ContentType == "star":
							var star = Star.instance()
							get_node("/root").get_child(0).get_node("Layer1").add_child(star)
							star.global_transform = star.global_transform.translated(self.global_position)

						#self.collision_layer = 0  	#remove collision layer so that adjacent blocks can  be hit without cast
													#collision layer is just a bitmap represented in decimal for setting it (eg layers 1,2,3 = (int)7)... mask is the same
													# this is still true even though i've commented this code out hehe
						#self.collision_mask = 0
					$QuestionMarkSprite/AnimationPlayer.play("hit") #play hit animation every time
					
		
	hit_last_frame = hit
	