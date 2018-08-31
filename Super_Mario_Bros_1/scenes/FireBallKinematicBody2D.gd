extends KinematicBody2D

var gravity = 400
var is_bouncing = false
var x_speed = 1000
var velocity = Vector2(0,0)
var x_dir = 1
var go = true
var hit = false

func _ready():
	print("FIREBALL!!!")
	self.x_speed = x_speed * self.x_dir
	$AudioShoot.play()
	pass

func _physics_process(delta):
	if go:
		if !is_bouncing:
			self.velocity = Vector2(x_speed,abs(x_speed)) #straight diagonal downward
		else:
			var move_vector = Vector2(0,self.gravity/5)
			self.velocity += move_vector
			
		self.velocity = self.move_and_slide(self.velocity,Vector2(0,-1)) #move_and_slide converts velocity to pixels per second (so DO NOT delta your velocity)
		
		#kill stuff
		for i in range(self.get_slide_count()):
			var c = self.get_slide_collision(i)
			if c.collider and c.collider.is_in_group("enemies"):
				self.hit = true
				c.collider._on_shot()
				
		if !self.hit:
			#bounce
			if self.is_on_floor():
				self.velocity.y = -self.gravity * 2
				self.is_bouncing = true
			
			#obstical
			if self.is_on_wall():
				self.hit = true
				
		#explode
		if self.hit:
			$AudioExplode.play()
			$Sprite/AnimationPlayer.play("explode")
			self.go = false

	else:
		#if !$Sprite/AnimationPlayer.is_playing() and !$AudioExplode.playing:
		if !$Sprite/AnimationPlayer.is_playing():
			self.hide()
			$CollisionShape2D.disabled = true
		if !$AudioExplode.playing:
			self._kill_me()
		
func _kill_me():
	print("freeing FireBall")
	self.queue_free()




