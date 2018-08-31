extends "res://scenes/BaseEnemy.gd"

var is_shell = false
var is_shell_kicked = false

func _ready():
	pass
	
#node about _physics_process:
#	this method WILL get called twice if parent class also has it defined
#	you dont actually need to parent .call it or anything (godot finds all _physics_process references it seems)
#   this is why we have a do_physics_process class
func do_physics_process(delta):
	if self.go:
		if !self.is_shell:
			self.walk_force = 200
		else:
			self.walk_force = 1000
	.do_physics_process(delta)


func do_collisions(delta):
	if !self.is_shell:
		.do_collisions(delta)
	else:
		var hit_enemy = false
		#kill stuff
		if self.is_shell:
			for i in range(get_slide_count()):
				var c = get_slide_collision(i)
				#print(c.collider.name)
				if c.collider and c.collider.is_in_group("enemies"):
					hit_enemy = true
					print("turtle shell hit somebody")
					print(c.collider.name)
					c.collider._on_shot()
			
		if ( self.is_on_wall() and !hit_enemy ):
			walk_dir *= -1
			
		if walk_dir < 0:
			self.get_node("Sprite").flip_h = true
		else:
			self.get_node("Sprite").flip_h = false
			
		self.do_hits()


func _on_stomped(stomper):
	if !self.is_shell:
		self.get_node("squish").play()
		self.walk_dir = 0
		self.velocity.x = 0
		$Sprite/AnimationPlayer.play("shell")
		self.is_shell = true
	elif !is_shell_kicked:
		self._on_kicked(stomper)
	else:
		self.get_node("squish").play()
		self.walk_dir = 0
		self.velocity.x = 0
		self.is_shell_kicked = false

func _on_kicked(kicker):
	$shot.play()
	self.walk_dir = 1
	if kicker.global_position.x > self.global_position.x:
		self.walk_dir = -1
	self.is_shell_kicked = true
	
func can_kick():
	return self.is_shell && !self.is_shell_kicked