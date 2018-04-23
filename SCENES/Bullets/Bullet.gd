extends Spatial

export(int) var damage = 1
export(float) var maxRange = 50.0

var __intendedTarget = null

func shootAt(baddie):
	if (self.global_transform.origin.distance_to(baddie.global_transform.origin) > self.maxRange):
		print("bullet at "+str(self.transform.origin) + " is too far from " + str(baddie) )
		self.visible = false
		self.queue_free()
		return
		
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
		__intendedTarget.takeDamage(damage)
	self.queue_free()

func _process(delta):
	print("bullet at "+str(self.transform.origin))

func _on_Area_area_shape_entered(area_id, area, area_shape, self_shape):
	var hitGuy = area.get_node("../..")
	if (hitGuy != null):
		if (hitGuy.get("takeDamage")):
			print ("get down, mr president")
			hitGuy.takeDamage(damage)
			self.queue_free()
