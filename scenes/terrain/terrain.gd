extends GridMap
tool

onready var checkmark_scene = load("res://scenes/terrain/Checkmark.tscn")

#Cell indicies
export var invalid_cells = [-1, 1]
export(int) var checkpoint_cell = 2

var _towers = []
var _checkmarks = null


#A list of checkpoints by X and Y. First is spawn, last is end
export var checkpoints = [[0, 0]] setget _set_checkpoints

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	show_open_tiles()
	pass

func show_open_tiles():
	
	#Get all open tiles if we aren't already showing
	if _checkmarks:
		return
	
	#Make a bunch
	_checkmarks = []
	for tile in get_open_tiles():
		#We need to get the position we want the checkmark at
		var t = map_to_world(tile.x, tile.y, tile.z)
		
		#Make the checkmark
		var checkmark = checkmark_scene.instance()
		checkmark.translate(t)
		_checkmarks.append(checkmark)
		add_child(checkmark)

func clear_open_tiles():
	#Go through them all
	for checkmark in _checkmarks:
		checkmark.queue_free()
	
	#And stop paying attention to them
	_checkmarks = null

func get_open_tiles():
	#Get a list of all 'good' tiles by X and Y
	var open_tiles = []
	
	#Go through each cell
	for cell_position in get_used_cells():
		#Could we add a tower here?
		if can_add_tower(cell_position.x, cell_position.z):
			#Add it to our list
			open_tiles.append(cell_position)
			
	#Return the list
	return open_tiles

func can_add_tower(x, y):
	#Return if a tower can be added at a particular location
	
	#Do we have something blocking that spot?
	var item_index = get_cell_item(x, 0, y)
	
	#Is it an empty or invalid cell
	if item_index in invalid_cells:
		#We can't do this spot
		return false
		
	#What about towers, was there one there already?
	if _get_tower_at_location(x, y):
		return false
		
	#We are on a good tile and nothing else is occupying it
	return true
	
func add_tower(x, y, tower):
	#Add a tower if possible
	
	#Double check we can use this spot
	if not can_add_tower(x, y):
		return
		
	#Add the tower
	_towers.append(tower)
	
func remove_tower(x, y):
	#Remove a tower, return the to-be-destroyed tower
	
	#Is there a tower here?
	var tower = _get_tower_at_location(x, y)
	if tower:
		_towers.remove(_towers.find(tower))
		return tower
	
	#Did not find the tower
	return null 
	
func _get_tower_at_location(x, y):
	#Go through each tower
	for tower in _towers:
		if tower.x == x and tower.y == y:
			return tower
	
	#No tower found
	return null
	
func _set_checkpoints(new_checkpoints):
	#First clear out all the old checkpoints
	_clear_checkpoints()
	
	#Now set the new checkpoints
	for checkpoint in new_checkpoints:
		set_cell_item(checkpoint[0], 0, checkpoint[1], checkpoint_cell)
	
func _clear_checkpoints():
	#Go through each tile
	for tile in get_used_cells():
		#Is it a checkpoint?
		if get_cell_item(tile.x, tile.y, tile.z) == checkpoint_cell:
			#Clear it 
			set_cell_item(tile.x, tile.y, tile.z, -1)

func find_path(start_position, end_position):
	
	#First, get all cells
	var open_cells = get_used_cells()
	var closed_cells = []