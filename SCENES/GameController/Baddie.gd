extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

# All baddie characteristics
export var baddieHealth = 100 # Weakest HP
export var baddieSpeed = 1 # Slowest move speed
export var powerDrain = 0 # No drain when hit

signal got_hit(damage)
signal just_died

var currentHealth = 1
var nextCheckpointIndex = 0 # Which checkpoint is this guy trying to walk to?

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	# Set up HP
	currentHealth = baddieHealth
	
	# Make sure the mover is the right speed!
	var mover = get_node("WaypointFollower")
	mover.speed = baddieSpeed
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Area_input_event(camera, event, click_position, click_normal, shape_idx):
	var type = event.get_class()
	if type == "InputEventMouseButton":
		if event.button_index == BUTTON_LEFT and event.pressed:
			print("pressed! " + String(currentHealth))
			currentHealth = currentHealth - 1
			# do something
			checkIfDead()
			pass
	pass # replace with function body

func checkIfDead():
	if currentHealth <= 0:
		# Dead!
		emit_signal("just_died")

func _on_WaypointFollower_TranslationFinishedSignal(sender):
	pass # replace with function body
