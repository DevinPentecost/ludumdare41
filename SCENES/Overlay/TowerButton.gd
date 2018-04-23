extends Container

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TowerButtonPressed(towerName, towerInstancePath)
signal TowerButtonUnpressed(towerName, towerInstancePath) 

#this doubles as the "dropped data"
#don't set this
export(String) var towerText = "hello"
#don't set this
export(StreamTexture) var towerIcon = str("res://UISPRITES/cursorSword.png")
#set this
export(String) var towerInstancePath = String("res://SCENES/Towers/KisserTower.tscn")

var bgUp = str("res://UISPRITES/buttonSquare_beige.png")
var bgDown = str("res://UISPRITES/buttonSquare_grey_pressed.png")
var bgHover = str("res://UISPRITES/buttonSquare_grey.png")
var bgDisabled = str("res://UISPRITES/buttonSquare_blue.png")

var ready = false

func __loadTexture(path):
	var loadedText = ImageTexture.new()
	loadedText.load(path)
	return loadedText

#set this to prevent ability to drag'n'drop
export(bool) var disabled setget disabled_set,disabled_get

export(bool) var toggledOn setget toggledOn_set,toggledOn_get

func disabled_set(newvalue):
	disabled=newvalue
	if (ready):
		print(self.towerText + " disabled " + str(newvalue))
		if disabled:
			self.get_node("./NinePatchRect").texture = bgDisabled
			emit_signal("TowerButtonUnpressed", self.towerText, towerInstancePath)
		else:
			self.get_node("./NinePatchRect").texture = bgUp

func disabled_get():
	return disabled # getter must return a value
	
func toggledOn_set(newvalue):
	if (ready):
		if disabled:
			self.get_node("./NinePatchRect").texture = bgDisabled
			toggledOn = false
		else:
			toggledOn=newvalue
			if (toggledOn):
				self.get_node("./NinePatchRect").texture = bgDown
				emit_signal("TowerButtonPressed", self.towerText, towerInstancePath)
			else:
				self.get_node("./NinePatchRect").texture = bgUp
		print(self.towerText + " toggled " + str(newvalue))

func toggledOn_get():
	return toggledOn && !disabled # getter must return a value

func _ready():
	bgUp = __loadTexture(bgUp)
	bgDown = __loadTexture(bgDown)
	bgHover = __loadTexture(bgHover)
	bgDisabled = __loadTexture(bgDisabled)
	
	var tempInstance = (load(towerInstancePath)).instance().find_node("Tower")
	self.towerText = tempInstance.towerType
	self.towerIcon = tempInstance.towerIcon
	
	
	
	self.disabled = true
	self.get_node("./NinePatchRect/VBoxContainer/TowerIcon").texture = __loadTexture(self.towerIcon)
	self.get_node("./NinePatchRect/VBoxContainer/TowerLabel").text = self.towerText
	self.get_node("./NinePatchRect").texture = bgDisabled
	
	
	ready = true

func __down():
	self.get_node("./NinePatchRect").texture = bgDown
func __up():
	self.get_node("./NinePatchRect").texture = bgUp
func __hover():
	self.get_node("./NinePatchRect").texture = bgHover
func __disable():
	self.get_node("./NinePatchRect").texture = bgDisabled

func __getPreview():
	var drag = TextureRect.new()
	drag.texture = self.towerIcon
	return drag

func get_drag_data(pos):
	if disabled:
		return null
	else:
		set_drag_preview(__getPreview())
		return self.towerText

# don't receive drops
func can_drop_data(pos, data):
	return false

func drop_data(pos, data):
	print("dropping tower data")

func _on_TowerButton_mouse_entered():
	if disabled:
		__disable()
	else:
		if (toggledOn):
			__down()
		else:
			__hover()

func _on_TowerButton_mouse_exited():
	if disabled:
		__disable()
	else:
		if (toggledOn):
			__down()
		else:
			__up()

func _on_TowerButton_gui_input(ev):
	var type = ev.get_class()
	if type == "InputEventMouseButton":
		if ev.button_index == BUTTON_LEFT:
			if disabled:
				__disable()
			elif ev.pressed:
				toggledOn = !toggledOn
				if (toggledOn):
					__down()
					emit_signal("TowerButtonPressed", self.towerText, towerInstancePath)
				else:
					__hover()
					emit_signal("TowerButtonUnpressed", self.towerText, towerInstancePath)
			else:
				__hover()