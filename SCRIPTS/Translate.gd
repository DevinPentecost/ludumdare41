extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TranslationFinishedSignal(sender) 

var waypoints = PoolVector3Array()

func AppendWaypoint(vector3):
	if (waypoints.size() > 0):
		if (!__closeEnough(waypoints[waypoints.size() - 1], vector3)):
			waypoints.append(vector3)

func ClearWaypoints():
	waypoints.clear()
	emit_signal("TranslationFinishedSignal", self)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _fixed_process(delta):
	#move towards target destination
	move(velocity*delta)
	   
	#remove waypoint once we get close
	if ((waypoints.size() != 0) && (__closeEnough(get_pos(), waypoints[0]))):
		waypoints.remove(0)
		#yell if we are done
		if (waypoints.size() == 0):
			emit_signal("TranslationFinishedSignal", self)
		#start going to next waypoint if there is one
		else:
			var angle = get_angle_to(target)
			velocity.x = speed*sin(angle)
			velocity.y = speed*cos(angle)

func __closeEnough(vectorA, vectorB):
	return (vectorA.distance_to(vectorB) <= 1)