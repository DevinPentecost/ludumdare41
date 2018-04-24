extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TowerPicked(tower)

#don't set this
export(String) var currentTower = null
export(String) var currentTowerPath = null


func __isDragging():
	return self.get_node("DragReceiver").visible

func __dropped(dropPos, dropTower):
	if (dropTower != null):
		print("I dropped a " + str(dropTower) + " tower at " + str(dropPos))

func __pressed(a, path):
	#print("press encountered: "+str(a))
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText != a):
			N.toggledOn = false
	self.emit_signal("TowerPicked", a)
	print(str(self) + " emits TowerPicked: "+str(a))
	self.currentTower = a
	self.currentTowerPath = path

func __unpressed(a, path):
	#print("unpress encountered: "+str(a))
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if N.toggledOn:
			return
	self.currentTower = null
	self.currentTowerPath = null
	self.emit_signal("TowerPicked", self.currentTower)
	print(str(self) + " emits TowerPicked: (unpressed) "+str(self.currentTower))

func _ready():
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		N.connect("TowerButtonPressed", self, "__pressed")
		N.connect("TowerButtonUnpressed", self, "__unpressed")

func unselectAll():
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		N.toggledOn = false
		currentTower = null
		currentTowerPath = null

func setAvailable(towerString, enabled):
	for N in self.get_node("./Container/NinePatchRect/HBoxContainer").get_children():
		if (N.towerText == towerString):
			print("ui: " + towerString + " = " + str(enabled))
			N.disabled = !enabled

func update_bone_count(bones):
	#Set the text
	$BonesContainer/NinePatchRect/BoneCount.text = str(bones)
	
	#We can disable UI based on the bone counts
	for tower_button in $Container/NinePatchRect/HBoxContainer.get_children():
		#Get the cost of the tower
		var purchasable = bones >= tower_button.towerCost
		tower_button.disabled = !purchasable
		
func update_status(wave, health):
	#Set up the text fields
	$StatusContainer/NinePatchRect/HBoxContainer/WaveContainer/WaveCount.text = str(wave)
	$StatusContainer/NinePatchRect/HBoxContainer/HealthContainer/HealthCount.text = str(health)
	
func player_lost():
	#Show the button
	var button = $RestartButton
	button.visible = true
	
	#Fade it in
	var tween = $RestartButton/Tween
	tween.interpolate_property(button, "modulate.alpha", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 2, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func _on_RestartButton_pressed():
	#Go back to the main menu
	get_tree().change_scene("res://SCENES/mainmenu/main.tscn")
	pass # replace with function body
