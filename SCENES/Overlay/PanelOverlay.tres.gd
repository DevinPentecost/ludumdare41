extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TowerPicked(tower)

export(String) var currentTower = null

func __isDragging():
	return self.get_node("DragReceiver").visible

func __dropped(dropPos, dropTower):
	if (dropTower != null):
		print("I dropped a " + str(dropTower) + " tower at " + str(dropPos))

func __pressed(a):
	print("press encountered: "+str(a))
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText != a):
			N.toggledOn = false
	self.emit_signal("TowerPicked", a)
	self.currentTower = a
	

func _ready():
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		N.connect("TowerButtonPressed", self, "__pressed")

func setAvailable(towerString, enabled):
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText == towerString):
			print("ui: " + towerString + " = " + str(enabled))
			N.disabled = !enabled