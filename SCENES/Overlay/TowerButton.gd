extends Container

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

signal TowerButtonPressed(towerName) 

#this doubles as the "dropped data"
export(String) var towerText = "hello"
export(StreamTexture) var towerIcon = null

export(StreamTexture) var bgUp = null
export(StreamTexture) var bgDown = null
export(StreamTexture) var bgHover = null
export(StreamTexture) var bgDisabled = null

#set this to prevent ability to drag'n'drop
var disabled setget disabled_set,disabled_get

func disabled_set(newvalue):
	disabled=newvalue
	if disabled:
		self.get_node("./NinePatchRect").texture = bgDisabled
	else:
		self.get_node("./NinePatchRect").texture = bgUp

func disabled_get():
	return disabled # getter must return a value


func _ready():
	self.disabled = true
	self.get_node("./NinePatchRect/VBoxContainer/TowerIcon").texture = self.towerIcon
	self.get_node("./NinePatchRect/VBoxContainer/TowerLabel").text = self.towerText
	self.get_node("./NinePatchRect").texture = bgDisabled

func __down():
	self.get_node("./NinePatchRect").texture = bgDown
func __up():
	self.get_node("./NinePatchRect").texture = bgUp
func __hover():
	self.get_node("./NinePatchRect").texture = bgHover
func __disable():
	self.get_node("./NinePatchRect").texture = bgDisabled


func get_drag_data(pos):
	if disabled:
		return null
	else:
		var drag = TextureRect.new()
		drag.texture = self.towerIcon
		set_drag_preview(drag)
		return self.towerText

func can_drop_data(pos, data):
	return false

func drop_data(pos, data):
	print("dropping tower data")

func _on_TowerButton_mouse_entered():
	if disabled:
		__disable()
	else:
		__hover()

func _on_TowerButton_mouse_exited():
	if disabled:
		__disable()
	else:
		__up()

func _on_TowerButton_gui_input(ev):
	var type = ev.get_class()
	if type == "InputEventMouseButton":
		if ev.button_index == BUTTON_LEFT:
			if disabled:
				__disable()
			elif ev.pressed:
				__down()
				emit_signal("TowerButtonPressed", self.towerText)
			else:
				__hover()