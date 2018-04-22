extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#not really used anymore


signal DroppedTowerAt(dropPos, dropData) 


export(Vector2) var dropPos
export(String) var dropData

var pendingClose = false

func _ready():
	self.visible = false

func can_drop_data(position, data):
	self.dropPos = position
	self.dropData = data
	true

func drop_data(position, data):
	print("dropped " + str(data) + " at " + str(position))
	self.emit_signal("DroppedTowerAt", dropPos, dropData)
	self.pendingClose = true

func _on_DragReceiver_gui_input(ev):
	if (!Input.is_mouse_button_pressed(BUTTON_LEFT)):
		self.emit_signal("DroppedTowerAt", dropPos, dropData)
		self.pendingClose = true
	if (Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		self.pendingClose = true

func _process(delta):
	if (pendingClose):
		self.visible = false
		self.pendingClose = false