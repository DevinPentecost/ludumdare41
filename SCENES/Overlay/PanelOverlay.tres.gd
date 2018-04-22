extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func setAvailable(towerString, enabled):
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText == towerString):
			N.disabled = !enabled