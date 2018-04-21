extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TranslationFinishedSignal(sender) 

export var speed = 4.0
#how tight the pather handles corners. value between 0 and 1
export var accl = 0.3

export(NodePath) var spatialToMove = NodePath("../")
var  __spatialNode = null

var velocity = Vector3(0.0, 0.0, 0.0)

var waypoints = []

# insert a global vector3 or a spatial to follow
func AppendWaypoint(vector3):
	print("going to " + str(vector3))
	waypoints.append(vector3)

func ClearWaypoints():
	waypoints.clear()
	emit_signal("TranslationFinishedSignal", self)

func _ready():
	self.__spatialNode = self.get_node(spatialToMove)

func _process(delta):
	#print("" + self.get_path() + " has " + str(waypoints.size()) + " points to go to" )
	if (waypoints.size() != 0):
		#move towards target destination
		__spatialNode.global_translate(velocity*delta)
		# look at new direction
		__spatialNode.look_at(velocity + __spatialNode.global_transform.origin, Vector3(0,1,0))
		
		#remove waypoint once we get close
		var targetCoord = waypoints[0]
		if (targetCoord.get("global_transform")):
			targetCoord = targetCoord.global_transform.origin
		#print(str(self.get_path()) + " at ("+str(__spatialNode.global_transform.origin) + ") ->  ("+str(targetCoord)+")" )
		
		if (__closeEnough(__spatialNode.global_transform.origin, targetCoord)):
			print("hit waypoint " + str(targetCoord))
			waypoints.remove(0)
			#yell if we are done
		if (waypoints.size() != 0):
			#start going to next waypoint if there is one
			var newDirection = Vector3(targetCoord - __spatialNode.global_transform.origin).normalized()
			
			velocity = ((newDirection * accl) + (velocity * (1 - accl))).normalized() * speed
			
	else:
		emit_signal("TranslationFinishedSignal", self)		

func __closeEnough(vectorA, vectorB):
	return (vectorA.distance_to(vectorB) <= .05)