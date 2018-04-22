extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Some debug stuff
export(Material) var visible_material = Color(1, 1, 1, 0.25)
export(Material) var hidden_material = Color(1, 1, 1, 0)

signal tile_highlighted(tile)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	self.mesh = self.mesh.duplicate()
	_show(false)
	pass

func _show(is_visible):
	#Are we visible?
	var target_material = hidden_material
	if is_visible:
		target_material = visible_material
	
	#Set the material of the mesh
	self.mesh.material = target_material

func _on_Area_input_event(camera, event, click_position, click_normal, shape_idx):
	pass # replace with function body


func _on_Area_mouse_entered():
	#Set the color
	_show(true)
	emit_signal("tile_highlighted", [self])


func _on_Area_mouse_exited():
	_show(false)
	pass # replace with function body
