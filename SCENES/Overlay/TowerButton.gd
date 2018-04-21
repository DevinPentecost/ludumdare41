extends Button

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export(Texture) var towerIcon = null
export(String) var towerText = "hello"

func _ready():
	self.get_node("./NinePatchRect/VBoxContainer/TowerIcon").texture = self.towerIcon
	self.get_node("./NinePatchRect/VBoxContainer/TowerLabel").text = self.towerText

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
