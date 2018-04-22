extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func shootAt(baddie):
	var wayFinder = self.get_node("WaypointFollower")
	wayFinder.AppendWaypoint(baddie)
	wayFinder.connect("TranslationFinishedSignal", self, "__missingTargetHandler")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func __missingTargetHandler():
	print("bullet has nowhere to go")
	self.queue_free()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
