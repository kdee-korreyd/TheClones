extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export (String) var anchor_animation
var anchored_body = null

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	if $FlagPoleAnimationPlayer.is_playing():
		self.anchored_body.global_transform = $Anchor1.get_global_transform()
		if self.anchor_animation and self.anchored_body.get_node("mario-normal-small/AnimationPlayer").has_animation(self.anchor_animation):
			if self.anchored_body.get_node("mario-normal-small/AnimationPlayer").assigned_animation != self.anchor_animation:
				print("playing animation " + self.anchor_animation)
				self.anchored_body.get_node("mario-normal-small/AnimationPlayer").play(self.anchor_animation)
	
		print(self.anchor_animation)
	else:
		if self.anchored_body:
			self.anchored_body.is_anchored = false
			self.anchored_body = null
	pass

func _on_FlagCollisionArea_body_entered(body):
	$FlagPoleAnimationPlayer.play("flag_slide")
	self.anchored_body = body
	self.anchored_body.is_anchored = true
