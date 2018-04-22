extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TranslationFinishedSignal(sender) 

export var speed = 4.0
#how tight the pather handles corners. value between 0 and 1
export var accl = 0.52
export var rotAccl = 0.002

export(NodePath) var spatialToMove = NodePath("../")
var  __spatialNode = null

var __leftoverSpeed = 0.0

var velocity = Vector3(0.0, 0.0, 0.0)
var rotVelocity = Vector3(0.0, 0.0, 0.0)

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


func __move(delta):
	#print("" + self.get_path() + " has " + str(waypoints.size()) + " points to go to" )
	if (waypoints.size() != 0):
		# Do we need to translate from spatial to vector3?
		# Is this a spatial?
		var targetCoord = waypoints[0]
		if typeof(targetCoord) != TYPE_VECTOR3:
			if (targetCoord.get("global_transform")):
				targetCoord = targetCoord.global_transform.origin
			#print(str(self.get_path()) + " at ("+str(__spatialNode.global_transform.origin) + ") ->  ("+str(targetCoord)+")" )
		
		#move towards target destination
		var projectedVelocity = velocity * delta
		var direction = projectedVelocity.normalized()
		var projectedDistance = projectedVelocity.length()
		var maxDistance = targetCoord.distance_to(__spatialNode.global_transform.origin)
		var maxSpeed = min(projectedDistance, maxDistance)
		if (maxDistance < projectedDistance):
			velocity = direction * maxSpeed
			__leftoverSpeed = projectedDistance - maxDistance
		else:
			velocity = projectedVelocity
			__leftoverSpeed = 0.0
		
		__spatialNode.global_translate(projectedVelocity)

		# look at new direction
		__spatialNode.look_at((rotVelocity * delta) + __spatialNode.global_transform.origin, Vector3(0, 1, 0))
		
		#remove waypoint once we get close
		if (__closeEnough(__spatialNode.global_transform.origin, targetCoord)):
			#print("hit waypoint " + str(targetCoord))
			waypoints.remove(0)
			#yell if we are done
		if (waypoints.size() != 0):
			#start going to next waypoint if there is one
			var newDirection = Vector3(targetCoord - __spatialNode.global_transform.origin).normalized()
			velocity = ((newDirection * accl) + (velocity * (1 - accl))).normalized() * speed
			rotVelocity = ((newDirection * rotAccl) + (velocity * (1 - rotAccl))).normalized()
	else:
		__leftoverSpeed = 0.0
		emit_signal("TranslationFinishedSignal", self)

func _process(delta):
	__move(delta)
	while (__leftoverSpeed > 0.0):
		__move(delta)

func __closeEnough(vectorA, vectorB):
	var distance = vectorA.distance_to(vectorB)
	return (distance <= .05)
	
	# End of file
	