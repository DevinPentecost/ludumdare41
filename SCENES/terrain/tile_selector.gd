extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Some debug stuff
export(Material) var visible_material = Color(1, 1, 1, 0.25)
export(Material) var hidden_material = Color(1, 1, 1, 0)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	self.mesh = self.mesh.duplicate()
	_show(true)
	pass

func _show(is_visible):
	#Are we visible?
	var target_material = hidden_material
	if is_visible:
		target_material = visible_material
	
	#Set the material of the mesh
	self.mesh.material = target_material