extends "res://scenes/KBMario.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var collision_shape
var collision_shape_ducking

func _ready():
	print("callng MarioBig ready")
	is_big = true
	# Called when the node is added to the scene for the first time.
	# Initialization here
	collision_shape = preload("res://scenes/KBMarioBigCollisionShape.tres")
	collision_shape_ducking = preload("res://scenes/KBMarioBigDuckCollisionShape.tres")
	self.state_obj.is_ducking = false
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func grow():
	$"mario-normal-small/AnimationPlayer".play("grow")
	$AudioGrow.play()
	self.disable_controls = true
	self.disable_movement = true
	self.is_transitioning = true
	#stop enemies
	get_tree().call_group("enemies", "do_disable_movement")
	
	
func shrink():
	$"mario-normal-small/AnimationPlayer".play_backwards("grow")
	$AudioShrink.play()
	self.disable_controls = true
	self.disable_movement = true
	self.is_transitioning = true
	self.is_shrinking = true
	get_tree().call_group("enemies", "do_disable_movement")
	
func custom_controls(delta):
	if Input.is_action_pressed("ui_down"):
		self.state_obj.is_ducking = true
		$CollisionShape2D.position = Vector2(0,32)
		$CollisionShape2D.shape = collision_shape_ducking
	else:
		self.state_obj.is_ducking = false
		$CollisionShape2D.position = Vector2(0,3)
		$CollisionShape2D.shape = collision_shape
		
	#if Input.is_action_pressed("ui_down"):
	#	self.is_ducking = true
	#	$CollisionShape2D.disabled = true
	#	$CollisionShape2DDucking.disabled = false
	#else:
	#	self.is_ducking = false
	#	$CollisionShape2D.disabled = false
	#	$CollisionShape2DDucking.disabled = true


func custom_animations(delta):
	if self.state_obj.is_ducking:
		$"mario-normal-small/AnimationPlayer".play("duck")
	elif $"mario-normal-small/AnimationPlayer".assigned_animation == "duck":
		$"mario-normal-small/AnimationPlayer".play("idle")