extends GridMap
tool

onready var checkmark_scene = load("res://scenes/terrain/Checkmark.tscn")
onready var path_scene = load("res://scenes/terrain/Path.tscn")

#Cell indicies
export var invalid_cells = [-1, 1]
export(int) var checkpoint_cell = 2

signal new_path_ready(newPathSteps)

var _towers = []
var _checkmarks = null
var _paths = []


#A list of checkpoints by X and Y. First is spawn, last is end
export var checkpoints = [[0, 0]] setget _set_checkpoints

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	show_open_tiles()
	var newPath = find_path(Vector2(-1, 2), Vector2(4, 2))
	emit_signal("new_path_ready", newPath)
	show_path(newPath)
	pass

func show_path(steps):
	#Go through each step in the path
	var new_path = []
	for position in steps:
		#Make a new path scene and put it there
		var path = path_scene.instance()
		path.translate(position)
		new_path.append(path)
		add_child(path)
	
	#We've gotten them all
	_paths.append(new_path)
	
func clear_paths():
	#Get them all
	for path in _paths:
		#For each node
		for path_node in path:
			#Kill it
			path_node.queue_free()
	
	#Clear the list
	_paths = []

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
		if tile_is_open(cell_position.x, cell_position.z):
			#Add it to our list
			open_tiles.append(cell_position)
			
	#Return the list
	return open_tiles

func tile_is_open(x, y):
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
	if not tile_is_open(x, y):
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
	
	#Open and closed tiles
	var current_position = start_position
	var open = [{'g': 0, 'f': 0, 'pt': start_position, 'parent':null}]
	var closed = []
	
	#While we haven't run out of tiles...
	while open:
		
		#Find the smallest score and remove it
		var index = _smallest_f(open)
		var next_step = open[index]
		open.remove(index)
		closed.append(next_step)
		
		#Did we reach the end?
		if next_step.pt == end_position:
			#We did it
			var path = []
			while next_step.parent:
				#Move to the next parent
				next_step = next_step.parent
				
				#Get the world position to move to
				path.append(map_to_world(next_step.pt.x, 0, next_step.pt.y))
			
			#Return the path
			return path
		
		#Check adjacent tiles
		for pos in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
			#Are we ignoring this tile?
			var adjacent_tile = next_step.pt + Vector2(pos[0], pos[1])
			
			#Did we already close this one?
			if _search_in_tiles(adjacent_tile, closed):
				continue
			
			#Is this a valid tile?
			if tile_is_open(adjacent_tile.x, adjacent_tile.y):
				#Add it
				
				#Get the distance to the end
				var h = abs(adjacent_tile.x - end_position.x) + abs(adjacent_tile.y - end_position.y)
				var new_tile = {'g': next_step.g + 1, 'f': h + next_step.g + 1, 'pt': adjacent_tile, 'parent': next_step}
				open.append(new_tile)
	
	#Couldn't find a path
	return
	
func _search_in_tiles(position, tiles):
	#Check each index
	for index in range(tiles.size()):
		if tiles[index].pt == position:
			#We're golden
			return index
	#Didn't find it
	return false

func _search_in_cells(position):
	#Check all cells
	for cell in get_used_cells():
		#Position used in cells?
		if cell == position:
			return get_cell_item(cell.x, cell.y)

func _smallest_f(tiles):
	#Find the shortest index
	var index = 0
	for i in range(tiles.size()):
		#Is it shorter?
		if tiles[i].f < tiles[index].f:
			#Use this one
			index = i
	return index