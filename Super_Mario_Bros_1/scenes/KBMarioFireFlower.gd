extends "res://scenes/KBMarioBig.gd"

var already_fireballing = false
var prev_animation = null

func _ready():
	print("callng MarioFireFlower ready")
	._ready() #call parent ready
	self.is_fire = true
	self.state_obj.is_fireballing = false
	
func custom_controls(delta):
	.custom_controls(delta)
	if Input.is_action_pressed("ui_b"):
		if self.state_obj.is_fireballing:
			self.already_fireballing = true
		else:
			self.state_obj.is_fireballing = true
	else:
		self.state_obj.is_fireballing = false
		self.already_fireballing = false
	
func custom_animations(delta):
	.custom_animations(delta)
	if self.state_obj.is_fireballing and !self.already_fireballing:
		prev_animation = $"mario-normal-small/AnimationPlayer".current_animation
		if ( !prev_animation ):
			prev_animation = "idle"
		if ( prev_animation != "fireball" ):
			$"mario-normal-small/AnimationPlayer".animation_set_next("fireball",prev_animation)
			$"mario-normal-small/AnimationPlayer".play("fireball")
			#really dont want to do this here but I will for now since this is just the REALLY rough draft
			var fireball = load("res://scenes/FireBallKinematicBody2D.tscn").instance()
			if $"mario-normal-small".flip_h:
				fireball.x_dir = -1
			self.add_collision_exception_with(fireball) #don't hit your own fireball
			get_node("/root").get_child(0).get_node("Layer1").add_child(fireball)
			fireball.global_transform = self.get_global_transform().translated(Vector2(0,-50))
			
			
			