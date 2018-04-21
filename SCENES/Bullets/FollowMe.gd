extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(NodePath) var bullet = NodePath("../../Bullet")

func _ready():
	var target = self.get_node(bullet).find_node("WaypointFollower", true, true)
	print("" + self.get_path() + " listening to "+target.get_path())
	target.connect("TranslationFinishedSignal", self, "__addPoint")

func __addPoint(a):
	print("path point callback hit")
	a.AppendWaypoint(self)