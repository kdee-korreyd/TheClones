extends Node
export (PackedScene) var Mob

# class member variables go here, for example:
var score

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	randomize() #seed randomization
	#new_game()


#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()

	
func new_game():
	score = 0
	$Player.start($StartPosition2D.position)
	$StartTimer.start()


func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()


func _on_ScoreTimer_timeout():
	score += 1


func _on_MobTimer_timeout():
	$MobPath2D/MobSpawnLocation.set_offset(randi())
	var mob = self.Mob.instance()
	add_child(mob)
	var mob_rotation = $MobPath2D/MobSpawnLocation.rotation + PI / 2
	mob_rotation += rand_range(-PI / 4, PI / 4)
	mob.position = $MobPath2D/MobSpawnLocation.position
	mob.rotation = mob_rotation
	mob.set_linear_velocity(Vector2(rand_range(mob.min_speed,mob.max_speed),0).rotated(mob_rotation))
	
