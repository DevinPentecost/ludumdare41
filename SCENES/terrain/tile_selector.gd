extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Some debug stuff
export(Material) var valid_material = Color(1, 1, 1, 0.25)
export(Material) var invalid_material = Color(1, 1, 1, 0)

#Position
var tile_position = Vector2(0, 0)
var is_valid = true

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_valid(false)
	pass

func set_valid(valid):
	#Are we visible?
	var target_material = invalid_material
	if valid:
		target_material = valid_material
	
	#Set the material of the mesh
	self.mesh.material = target_material
	
	#Set the var
	is_valid = valid