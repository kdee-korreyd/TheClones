extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export (String) var anchor_animation
var anchored_body = null
var can_pipe = false
var is_pipeing = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	if $AnimationPlayer.is_playing():
		self.anchored_body.global_transform = $Anchor1.get_global_transform()
		if self.anchor_animation and self.anchored_body.get_node("mario-normal-small/AnimationPlayer").has_animation(self.anchor_animation):
			if self.anchored_body.get_node("mario-normal-small/AnimationPlayer").assigned_animation != self.anchor_animation:
				print("playing animation " + self.anchor_animation)
				self.anchored_body.get_node("mario-normal-small/AnimationPlayer").play(self.anchor_animation)
	
		print(self.anchor_animation)
	else:
		if self.anchored_body and self.is_pipeing:
			#self.anchored_body.z_index = 1000
			self.anchored_body.is_anchored = false
			self.anchored_body = null
			self.is_pipeing = false
		elif self.anchored_body:
			if Input.is_action_pressed("ui_down"):
				self.is_pipeing = true
				self.anchored_body.is_anchored = true
				$AnimationPlayer.play("go")
				self.anchored_body.z_index = 0
	pass

func _on_CollisionArea_body_entered(body):
	if "can_pipe" in body:
		self.can_pipe =  true
		self.anchored_body = body

func _on_CollisionArea_body_exited(body):
	if "can_pipe" in body:
		if !$AnimationPlayer.is_playing():
			self.can_pipe = false
			self.anchored_body = null
