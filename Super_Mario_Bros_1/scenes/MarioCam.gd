extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#$Camera2D2.owner = $KBMario
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	#Note: camera options (from inspector) still take effect even
	# though I'm setting the x position here
	for i in self.get_children():
		if i.is_in_group("players"):
			$Camera2D.global_position.x = i.global_position.x