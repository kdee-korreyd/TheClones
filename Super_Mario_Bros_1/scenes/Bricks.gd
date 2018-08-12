extends StaticBody2D

export (PackedScene) var BrickBreakParticles

var hit_last_frame = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#$Particles2D.speed_scale = 4
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	


func _physics_process(delta):
	var hit = false
	if not $CollisionShape2D.disabled:
		var space_state = get_world_2d().direct_space_state
		var query = Physics2DShapeQueryParameters.new()
		query.set_shape($CollisionShape2D.shape)
		query.transform = self.global_transform.translated(Vector2(0,0.3))
		#query.transform = self.transform
		query.exclude = [self]
		#query.collision_layer = self.collision_layer
		var hits = space_state.intersect_shape(query) #unfortunately this DOES NOT take disabled into account (meaning it still intersects disabled stuff)

		#print(hits)
		for h in hits:
			if h.collider.has_node("BreakRayCast2D"):
				print(h.collider.name)
				#print(h.collider.metadata)
				#if h.collider.has_node("CollisionShape2D") and h.collider.get_node("CollisionShape2D").disabled:
				#	continue
				hit = true
				if not hit_last_frame: 
					# only do hit stuff if hitters cast is not hit anything else
					#  or if hitters cast is hitting self
					var do_hit = true
					if h.collider.get_node("BreakRayCast2D").is_colliding() and h.collider.get_node("BreakRayCast2D").get_collider() != self:
						print(h.collider.get_node("BreakRayCast2D").get_collider())
						do_hit = false
					print("test1" + str(h.collider.can_hit_stuff))
					if do_hit and h.collider.can_hit_stuff:
						h.collider.can_hit_stuff = false
						print("test1" + str(h.collider.can_hit_stuff))
						print(h.collider.name)
						$Sprite.hide()
						$CollisionShape2D.disabled = true
						var brokenbrick = BrickBreakParticles.instance()
						brokenbrick.position = self.global_position
						#self.add_child(brokenbrick)
						get_node("/root").get_child(0).add_child(brokenbrick) #add particle emmiter to root node instead (so we can free this one)
						brokenbrick.emitting = true
						brokenbrick.get_node("Hit").play()
						self.queue_free()
				
		hit_last_frame = hit