extends Container

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(StreamTexture) var towerIcon = null
export(String) var towerText = "hello"

export(StreamTexture) var bgUp = null
export(StreamTexture) var bgDown = null
export(StreamTexture) var bgHover = null

func _ready():
	self.get_node("./NinePatchRect/VBoxContainer/TowerIcon").texture = self.towerIcon
	self.get_node("./NinePatchRect/VBoxContainer/TowerLabel").text = self.towerText
	self.get_node("./NinePatchRect").texture = bgUp

func __down():
	self.get_node("./NinePatchRect").texture = bgDown
func __up():
	self.get_node("./NinePatchRect").texture = bgUp
func __hover():
	self.get_node("./NinePatchRect").texture = bgHover


func get_drag_data(pos):
	var drag = TextureRect.new()
	drag.texture = self.towerIcon
	set_drag_preview(drag)
	return self.towerText

func can_drop_data(pos, data):
	return false

func drop_data(pos, data):
	print("dropping tower data")
	towerText=data

func _on_TowerButton_mouse_entered():
	__hover()

func _on_TowerButton_mouse_exited():
	__up()

func _on_TowerButton_gui_input(ev):
	var type = ev.get_class()
	if type == "InputEventMouseButton":
		if ev.button_index == BUTTON_LEFT:
			if ev.pressed:
				__down()
			else:
				__hover()