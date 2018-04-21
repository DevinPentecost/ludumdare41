extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Some debug stuff
export(Color) var highlight_color = Color(1, 0, 0)
var normal_color = Color(1, 1, 1)


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _on_TileSelector_input_event(camera, event, click_position, click_normal, shape_idx):
	pass # replace with function body


func _on_TileSelector_mouse_entered():
	#Set the color
	print(self.material_override)
	
	pass # replace with function body


func _on_TileSelector_mouse_exited():
	pass # replace with function body
