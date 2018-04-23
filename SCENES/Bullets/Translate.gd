extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TranslationFinishedSignal(sender) 

export var speed = 4.0
#how tight the pather handles corners. value between 0 and 1
export var accl = 0.2

export(NodePath) var spatialToMove = NodePath("../")
var  __spatialNode = null

var __availSpeed = 0.0
var __prevVelocity = Vector3(0.0, 0.0, 0.0)

var __delayedTurn = Vector3(0.0, 0.0, 0.0)

var waypoints = []

# insert a global vector3 or a spatial to follow
func AppendWaypoint(vector3):
	#print("going to " + str(vector3))
	waypoints.append(vector3)

func ClearWaypoints():
	waypoints.clear()
	emit_signal("TranslationFinishedSignal", self)

func _ready():
	self.__spatialNode = self.get_node(spatialToMove)


func __move():
	# Store next waypoint as a Vector3 into targetCoord.
	# This might require casting from Spatial.
	var targetCoord = waypoints[0]
	if typeof(targetCoord) != TYPE_VECTOR3:
		if (targetCoord.get("global_transform")):
			targetCoord = targetCoord.global_transform.origin
			
	if (__closeEnough(__spatialNode.global_transform.origin, targetCoord)):
		waypoints.remove(0)
		return
	
	var distanceToTargetCoord = targetCoord.distance_to(__spatialNode.global_transform.origin)
	var desiredBearing = Vector3(targetCoord - __spatialNode.global_transform.origin).normalized()
	var desiredMove = desiredBearing * __availSpeed# * 4 #DEBUG
	
	var projectedVelocity = (desiredMove * accl) + (__prevVelocity * (1 - accl))
	var projectedDistanceMoved = projectedVelocity.length()

	#don't move past the next target
	
	if (projectedDistanceMoved >= distanceToTargetCoord):
		waypoints.remove(0)
		__availSpeed = min(0.0, __availSpeed - projectedDistanceMoved)

	__spatialNode.global_translate(projectedVelocity)
	
	
	__delayedTurn = ((__delayedTurn * 10) + projectedVelocity.normalized()).normalized()
	
	__spatialNode.look_at(__delayedTurn + __spatialNode.global_transform.origin, Vector3(0, 1, 0))
	
	__prevVelocity = projectedVelocity
	
	__availSpeed = __availSpeed - projectedVelocity.length()
	
func _process(delta):
	__availSpeed = speed * delta
	while (true):
		if (waypoints.size() == 0):
			emit_signal("TranslationFinishedSignal", self)
			break
		elif (waypoints[0] == null):
			waypoints.remove(0)
		elif (__availSpeed >= 0.0002):
			__move()
		else:
			__availSpeed = 0.0
			break

func __closeEnough(vectorA, vectorB):
	var distance = vectorA.distance_to(vectorB)
	return (distance <= .05)
	
	# End of file
	
