extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal dropHappened(towerString, dropPos)

func __isDragging():
	return self.get_node("DragReceiver").visible

func __dropped(dropPos, dropTower):
	if (dropTower == null):
		return
	print("I dropped a " + str(dropTower) + " tower at " + str(dropPos))
	emit_signal("dropHappened", dropTower, dropPos)

func __pressed(a):
	print("press encountered: "+str(a))
	self.get_node("DragReceiver").visible = true
	

func _ready():
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		N.connect("TowerButtonPressed", self, "__pressed")
	self.get_node("./DragReceiver").connect("DroppedTowerAt", self, "__dropped")

func setAvailable(towerString, enabled):
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText == towerString):
			print("ui: " + towerString + " = " + str(enabled))
			N.disabled = !enabled