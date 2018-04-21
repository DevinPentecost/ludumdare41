extends BaseButton

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(StreamTexture) var towerIcon = null
export(String) var towerText = "hello"

export(StreamTexture) var bgUp = null
export(StreamTexture) var bgDown = null

func _ready():
	self.icon = self.towerIcon
	self.get_node("./NinePatchRect/VBoxContainer/TowerIcon").texture = self.towerIcon
	self.get_node("./NinePatchRect/VBoxContainer/TowerLabel").text = self.towerText
	self.get_node("./NinePatchRect").texture = bgUp


func get_drag_data(pos):
	var drag = TextureRect.new()
	drag.texture = self.towerIcon
	set_drag_preview(drag)
	return self.towerText

func button_down ( ):
	print("down")
	self.get_node("./NinePatchRect").texture = bgDown

func button_up ( ):
	print("up")
	self.get_node("./NinePatchRect").texture = bgUp

func mouse_exited ( ):
	print("exit")
	self.get_node("./NinePatchRect").texture = bgUp


func can_drop_data(pos, data):
	return false

func drop_data(pos, data):
	print("dropping tower data")
	towerText=data
