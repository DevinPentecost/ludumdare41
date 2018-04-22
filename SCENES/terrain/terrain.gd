extends GridMap
tool

var checkmark_scene = preload("res://SCENES/terrain/Checkmark.tscn")
var path_scene = preload("res://SCENES/terrain/Path.tscn")
var selector_scene = preload("res://SCENES/terrain/TileSelector.tscn")

#Cell indicies. This MUST match what is used in the meshlibrary!
enum tile_types {
	OPEN = 2,
	BLOCKED = 0,
	CHECKPOINT = 1,
}
var walkable_cells = [tile_types.CHECKPOINT, tile_types.OPEN]
var buildable_cells = [tile_types.OPEN]

var kSizeWide = 10
var kSizeHigh = 10

var kNumTiles = kSizeWide * kSizeHigh
var map_size = Vector2(kSizeWide, kSizeHigh)

signal new_paths_ready(newPathsSteps)

signal tileClicked(coord)

var _towers = []
var _checkmarks = null
var _paths = []
var _tile_selector = null
var highlighted_tile_position = null

enum refresh {
	REFRESH,
	ALSO_REFRESH,
	CLEAR_MAP_CAREFUL,
}
export(refresh) var refresh_grid setget _refresh_grid

export(String, FILE) var initialMapStateJSONFile = null

#A list of checkpoints by X and Y. First is spawn, last is end
var checkpoints = [
							#Vector2(0,0),
							#Vector2(1,1),
							
							Vector2(10, 10),
							
							Vector2(40, 40),
							Vector2(15, 40),
							Vector2(25, 25),
							Vector2(35, 20),
							Vector2(20, 35),
							Vector2(40, 15),
							
							Vector2(5, 5),
						] setget _set_checkpoints

func setup_map_from_json(jsonFilePath):
	var file = File.new()
	file.open(jsonFilePath, file.READ)
	var text = file.get_as_text()
	var jsonParseResult = JSON.parse(text)
	if jsonParseResult.error != OK:
		return null
	
	var jsonObject = jsonParseResult.result
	
	# How many rows are there?
	kSizeHigh = jsonObject.size()
	# How many columns?
	kSizeWide = jsonObject[0].size()
	kNumTiles = kSizeWide * kSizeHigh
	map_size = Vector2(kSizeWide, kSizeHigh)
	for row in range (0, jsonObject.size()):
		for col in range (0, jsonObject[row].size()):
			set_cell_item(col, 0, row, jsonObject[row][col], 0)
	
	# Done!
	pass
	

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	# did the user select a pre-made map?
	if initialMapStateJSONFile != null:
		setup_map_from_json(initialMapStateJSONFile)
	
	_refresh_all()
	pass

func _refresh_grid(enum_value):
	refresh_grid = enum_value
	
	#Ignore the enum unless it's the clear
	if enum_value == refresh.CLEAR_MAP_CAREFUL:
		#Delete all the tiles
		clear()
	
	#_refresh_all()

func _refresh_all():
	#We want to make a grid, but leave everything down already
	clear_paths()
	_clear_checkpoints()
	
	#Also show open tiles and stuff
	_show_checkpoints()
	_rebuild_map()
	refresh_selector()
	
	#And pathfinding
	#refresh_pathfinding()
	
func _rebuild_map():
	#Get the current tiles
	var used_cells = get_used_cells()
	
	#Go through each possible tile
	for x in range(map_size.x):
		for y in range(map_size.y):
			#Does this tile already have something?
			if (Vector3(x, 0, y) in used_cells):
				var item = get_cell_item(x, 0, y)
				set_cell_item(x, 0, y, item, 0)
				continue
			
			if get_cell_item(x, 0, y) == INVALID_CELL_ITEM:
				#We can set it to the ground
				set_cell_item(x, 0, y, tile_types.OPEN)

func refresh_selector():
	#We know our size, so we know where to move it
	var position = map_size/2 * 2
	$Selector.transform.origin = Vector3(position.x, 0, position.y)
	
	#Set the shape size
	$Selector/CollisionShape.shape.extents = Vector3(position.x, 0.5, position.y)

func refresh_pathfinding():
	print("Refreshing Pathfinding")
	#For each checkpoint
	var prev_checkpoint = null
	var paths = []
	for checkpoint in checkpoints:
		
		#Did we have a previous?
		if prev_checkpoint != null:
			#We can make a path
			#print("Pathing: " + String(prev_checkpoint) + " to :" + String(checkpoint))
			var path = find_path(prev_checkpoint, checkpoint)
			
			
			
			#Could we find one?
			if not path:
				print("PATH IS BLOCKED! PANIC!")
			else:
			
				path.invert()
				#Show the path
				show_path(path)
				paths.append(path)
				
		#Set this spot as the previous
		prev_checkpoint = checkpoint
		
		
	
	#Emit that we have a new path
	emit_signal("new_paths_ready", paths)
	

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

func show_buildable_tiles():
	
	#Get all open tiles if we aren't already showing
	if _checkmarks:
		return
	
	#Make a bunch
	_checkmarks = []
	for tile in get_buildable_tiles():
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

func get_buildable_tiles():
	#Get a list of all 'good' tiles by X and Y
	var open_tiles = []
	
	#Go through each cell
	for cell_position in get_used_cells():
		#Could we add a tower here?
		if tile_is_buildable(cell_position.x, cell_position.z):
			#Add it to our list
			open_tiles.append(cell_position)
			
	#Return the list
	return open_tiles

func tile_is_open(x, y):
	#Return if a tower can be added at a particular location
	
	#Do we have something blocking that spot?
	var item_index = get_cell_item(x, 0, y)
	
	#Is it an empty cell
	if item_index in walkable_cells:
		#What about towers, was there one there already?
		if _get_tower_at_location(x, y):
			return false
		#We can do this spot
		return true
		
	#We are not on a good tile
	return false
	
func tile_is_buildable(x, y):
	#Check to see if we can build on it
	var item_index = get_cell_item(x, 0, y)
	
	#Is it empty?
	if item_index in buildable_cells:
		#No other towers there?
		if _get_tower_at_location(x, y):
			return false
		
		#We can build here
		return true
		
	#Can't build here
	return false
	
func add_tower(x, y, tower):
	#Add a tower if possible
	
	#Double check we can use this spot
	if not tile_is_open(x, y):
		return
		
	#Add the tower
	_towers.append(tower)
	set_cell_item(x, 0, y, tile_types.BLOCKED, 0)
	_refresh_all()
	
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
	
	#Set the checkpoints
	checkpoints = new_checkpoints
	
	#Make the checkpoints
	_show_checkpoints()

func _show_checkpoints():
	#Now set the new checkpoints
	for checkpoint in checkpoints:
		set_cell_item(checkpoint[0], 0, checkpoint[1], tile_types.CHECKPOINT)
	
func _clear_checkpoints():
	#Go through each tile
	for tile in get_used_cells():
		#Is it a checkpoint?
		if get_cell_item(tile.x, tile.y, tile.z) == tile_types.CHECKPOINT:
			#Clear it 
			set_cell_item(tile.x, tile.y, tile.z, INVALID_CELL_ITEM)

func find_path(start_position, end_position):
	
	#Open and closed tiles
	var open = [{'g': 0, 'f': 0, 'pt': start_position, 'parent':null}]
	var closed = []
	
	#While we haven't run out of tiles...
	var previous_tile = null
	var step_count = 0
	while open:
		if step_count > kNumTiles:
			#Error!
			return null
		
		step_count = step_count+1
		#Find the smallest score and remove it
		var index = _smallest_f(open, previous_tile)
		var next_step = open[index]
		previous_tile = next_step
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
			print("Pathfinding step count: ", step_count)
			return path
		
		#Check adjacent tiles
		for pos in __crappyPathRandom():
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
	print("Failed to find a path after steps: ", step_count)
	return null

var posList = [[-1, 0], [1, 0], [0, -1], [0, 1]]
func __crappyPathRandom():
	var popped = posList.pop_front()
	posList.append(popped)
	return posList

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

func _smallest_f(tiles, previous_tile):
	#Find the shortest index
	var index = 0
	for i in range(tiles.size()):
		#Is it shorter?
		if tiles[i].f < tiles[index].f or (tiles[i].f <= tiles[index].f and tiles[i].parent == previous_tile):
			#Use this one
			index = i
	return index

func _on_Selector_input_event(camera, event, click_position, click_normal, shape_idx):

	#Was something hovered?
	if event is InputEventMouseMotion:
		#Select it
		select_tile_at_world_position(click_position)
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			var pos = select_tile_at_world_position(click_position)
			print(str(self) + " emitting " + "tileClicked" +  str(pos.tile_position))
			self.emit_signal("tileClicked", pos)
	pass

func select_tile_at_world_position(target_position):
	#Get the tile under the mouse
	#print("target_position" + String(target_position))
	var logicalPos = world_to_map(target_position)
	#print("logicalPos" + String(logicalPos))
	var absolutePosition = Vector3(logicalPos.x, 0,  logicalPos.z)*2 + Vector3(1, 1, 1)
	#print("absolutePosition" + String(absolutePosition))
	#Make a selector mesh
	if not _tile_selector:
		_tile_selector = selector_scene.instance()
		add_child(_tile_selector)
	
	# Move it
	_tile_selector.transform.origin = absolutePosition
	_tile_selector.tile_position = logicalPos
	return _tile_selector
	

# End of file

