extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var __intendedTarget = null

func shootAt(baddie):
	print("bullet at "+str(self.transform.origin) + " will shoot " + str(baddie) )
	var wayFinder = self.get_node("WaypointFollower")
	wayFinder.AppendWaypoint(baddie)
	wayFinder.connect("TranslationFinishedSignal", self, "__missingTargetHandler")
	__intendedTarget = baddie

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	print("bullet at "+str(self.transform.origin))
	pass

func __missingTargetHandler(a):
	print("bullet has nowhere to go")
	if (__intendedTarget != null):
		__intendedTarget.takeDamage(1)
	self.queue_free()

func _process(delta):
	print("bullet at "+str(self.transform.origin))