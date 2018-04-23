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

var kSizeWide = 50
var kSizeHigh = 50
var tile_size = 7.2

var kNumTiles = kSizeWide * kSizeHigh
var map_size = Vector2(kSizeWide, kSizeHigh)

signal new_paths_ready(newPathsSteps)

signal tileClicked(coord)

var _towers = {}
var _checkmarks = null
var _paths = []
var _precalculated_can_build = {}

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
	var position = map_size/2 * tile_size
	$Selector.transform.origin = Vector3(position.x, 0, position.y)
	
	#Set the shape size
	$Selector/CollisionShape.shape.extents = Vector3(position.x, tile_size/2, position.y)

func refresh_pathfinding():
	print("Refreshing Pathfinding")
	#For each checkpoint
	var prev_checkpoint = null
	var paths = _get_all_paths()

	#Emit that we have a new path
	show_paths(paths)
	emit_signal("new_paths_ready", paths)
	
	#We need to recalculate invalid build spots
	_precalculated_can_build = {}

func _get_all_paths(blocked_tiles=null):
	#Go through each checkpoint
	var paths = []
	var prev_checkpoint = null
	for checkpoint in checkpoints:
		
		#Did we have a previous?
		if prev_checkpoint != null:
			#We can make a path
			#print("Pathing: " + String(prev_checkpoint) + " to :" + String(checkpoint))
			var path = find_path(prev_checkpoint, checkpoint, blocked_tiles)
			
			#Could we find one?
			if not path:
				print("PATH IS BLOCKED! PANIC!")
			else:
				#Invert the order to match source->dest
				path.invert()
				
			#Add it to our collection
			paths.append(path)
				
		#Set this spot as the previous
		prev_checkpoint = checkpoint
	
	#Give away them paths
	return paths

func validate_paths(paths):
	#Are any of them null?
	for path in paths:
		if path == null:
			return false

	#Made it through
	return true
	
func show_paths(paths, clear=true):
	#Make game objects for each
	if clear:
		clear_paths()
		
	for path in paths:
		#Show the path
		show_path(path)

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

#Shouldn't ever need this function, remove it if so
func __show_buildable_tiles():
	
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

#Shouldn't need this function
func __get_buildable_tiles():
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
	
var CHECK_PATHFINDING = true
func tile_is_buildable(x, y):
	#Check to see if we can build on it
	var item_index = get_cell_item(x, 0, y)
	var position = Vector2(x, y)

	#Is it empty?
	var empty_tile = (item_index in buildable_cells) and (_get_tower_at_location(x, y) == null)
	
	#Test if it breaks pathfinding too
	if CHECK_PATHFINDING and empty_tile:
		#Did we already have an answer?
		if _precalculated_can_build.has(position):
			return _precalculated_can_build[position]
		
		#Do the pathfinding, but give it an additional blocking tile
		var blocked_tiles = [Vector2(x, y)]
		var new_paths = _get_all_paths(blocked_tiles)
		var can_build = validate_paths(new_paths)
		_precalculated_can_build[position] = can_build
		return can_build
		
		
	else:
		#Not doing the pathfinding game
		return empty_tile

	#Not a good tile
	return false

	
func add_tower(x, y, tower):
	#Add a tower if possible
	
	#Double check we can use this spot
	if not tile_is_open(x, y):
		return
		
	#Add the tower
	if not _towers.has(x):
		_towers[x] = {}
	_towers[x][y] = tower

	
func remove_tower(x, y):
	#Remove a tower, return the to-be-destroyed tower
	
	#Is there a tower here?
	if _towers.has(x) and _towers[x].has(y):
		var tower = _towers[x][y]
		_towers[x].erase(y)
		return tower

	#Did not find the tower
	return null 
	
func _get_tower_at_location(x, y):
	#Go through each tower
	if _towers.has(x) and _towers[x].has(y):
		return _towers[x][y]

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


func _build_step(g_score, f_score, point, parent):
	return {
		'g': g_score,
		'f': f_score,
		'pt': point,
		'parent': parent,
	}

func find_path(start_position, end_position, blocked_tiles=null):
	
	#Open and closed tiles
	var open = [_build_step(0, 0, start_position, null)]
	var closed = {}

	#Were there any blocked tiles?
	if blocked_tiles != null:
		for blocked_tile in blocked_tiles:
			closed[blocked_tile] = true
	
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

		#No longer consider this tile as we are currently doing so
		open.remove(index)
		
		#Mark this X/Y as already used
		closed[next_step.pt] = true
		
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
		#for pos in __crappyPathRandom():
		for pos in posList:
			#Are we ignoring this tile?
			var adjacent_tile = next_step.pt + Vector2(pos[0], pos[1])
			
			#Did we already close this one?
			if closed.has(adjacent_tile):
				continue
			
			#Is this a valid tile?
			if tile_is_open(adjacent_tile.x, adjacent_tile.y):
				#Add it
				
				#Get the distance to the end
				var h = abs(adjacent_tile.x - end_position.x) + abs(adjacent_tile.y - end_position.y)

				#Build the new tile and add it to the front of the list
				var new_tile = _build_step(next_step.g + 1, h + next_step.g + 1, adjacent_tile, next_step)
				open.insert(0, new_tile)

			else:
				#Close the tile, we can't use it anyways
				closed[adjacent_tile] = true
	
	#Couldn't find a path
	print("Failed to find a path after steps: ", step_count)
	return null

var posList = [[-1, 0], [1, 0], [0, -1], [0, 1]]
func __crappyPathRandom():
	var popped = posList.pop_front()
	posList.append(popped)
	return posList

func _search_in_cells(position):
	#Check all cells
	for cell in get_used_cells():
		#Position used in cells?
		if cell == position:
			return get_cell_item(cell.x, cell.y)

func _smallest_f(tiles, previous_tile):
	#Find the shortest index
	var max_attempts = 10
	var index = 0
	for i in range(tiles.size()):
		#Is it shorter?
		if tiles[i].f < tiles[index].f or (tiles[i].f <= tiles[index].f and tiles[i].parent == previous_tile):
			#Use this one
			index = i
		
		#Give up after a bit, see if this speeds things up
		if i > max_attempts:
			break
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
	var logicalPos = world_to_map(target_position - transform.origin)
	
	#Did it move?
	if _tile_selector and _tile_selector.tile_position == logicalPos:
		#No tile movements, do nothing
		return _tile_selector
	
	#print("logicalPos" + String(logicalPos))
	var absolutePosition = Vector3(logicalPos.x, 0.25,  logicalPos.z)*tile_size + Vector3(tile_size, tile_size, tile_size)/2
	#print("absolutePosition" + String(absolutePosition))
	#Make a selector mesh
	if not _tile_selector:
		_tile_selector = selector_scene.instance()
		add_child(_tile_selector)
	
	# Move it
	_tile_selector.transform.origin = absolutePosition
	_tile_selector.tile_position = logicalPos
	
	#Can we place a tower there?
	var is_valid = tile_is_buildable(logicalPos.x, logicalPos.z)
	_tile_selector.set_valid(is_valid)
	return _tile_selector
	

# End of file

