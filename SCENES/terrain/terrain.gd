extends GridMap
tool

const pathfinding = preload("res://lib/pathfinding.gd")

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

var kSizeWide = 30
var kSizeHigh = 30
var tile_size = 7.2

var kNumTiles = kSizeWide * kSizeHigh
var map_size = Vector2(kSizeWide, kSizeHigh)

signal new_paths_ready(newPathsSteps)

signal tileClicked(coord)

var _towers = {}
var _checkmarks = null
var _path_nodes = []
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

							Vector2(29, 15),
							Vector2(25, 15),
							Vector2(25, 25),
							Vector2(5, 25),
							Vector2(5, 5),
							Vector2(15, 5),
							Vector2(15, 15),
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
	_paths = paths
	
	#Convert the paths to world space
	var w_paths = []
	for path in paths:
		var w_path = []
		
		if path == null:
			w_path = null
		for step in path:
			w_path.append(map_to_world(step.x, 0, step.y))
		w_paths.append(w_path)
			
	show_paths(w_paths)
	emit_signal("new_paths_ready", w_paths)
	
	
	#We need to recalculate invalid build spots
	_precalculated_can_build = {}

func _get_all_orders():
	#Get the orders from checkpoint to checkpoint
	var orders = []
	var prev_checkpoint = null
	
	for checkpoint in checkpoints:
		
		#Do we have a from?
		if prev_checkpoint != null:
			orders.append([prev_checkpoint, checkpoint])
		
		#Move forward
		prev_checkpoint = checkpoint
	
	#And that's all of them
	return orders
		

func _get_all_paths(blocked_tiles=null):
	#Go through each checkpoint
	var paths = []
	
	#Exclude any blocked tiles
	var walkable_tiles = _get_walkable_tiles()
	if blocked_tiles:
		for blocked_tile in blocked_tiles:
			if walkable_tiles.has(blocked_tile):
				walkable_tiles.erase(blocked_tile)
	
	#Get all of the unit's orders
	var orders = _get_all_orders()
	
	#Get the orders
	for order in orders:
		
		var path = get_path_for_order(order, walkable_tiles)
		paths.append(path)
		
	#Return the paths
	return paths
	
func get_path_for_order(order, walkable_tiles):
	
	#Get a path
	#Get the start time
	var start_time = OS.get_ticks_msec()
	var path = pathfinding.FindPathTiles(order[0], order[1], walkable_tiles)
	print("PATHFINDING TOOK THIS MANY MS ", OS.get_ticks_msec() - start_time)
	
	
	#Could we find one?
	if not path:
		print("PATH IS BLOCKED! PANIC!")
	else:
		#Invert the order to match source->dest
		path.invert()
	
	#Give away them paths
	return path

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
		#Was there a path?
		if path:
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
	_path_nodes.append(new_path)
	
func clear_paths():
	#Get them all
	for path in _path_nodes:
		#For each node
		for path_node in path:
			#Kill it
			path_node.queue_free()
	
	#Clear the list
	_path_nodes = []

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

var _cached_walkable_tiles = null
func _get_walkable_tiles():
	#Did we have a cache?
	if _cached_walkable_tiles != null:
		return _cached_walkable_tiles
	
	#Get a collection of tiles we can walk on
	var walkable_tiles = {}
	for x in range(map_size.x):
		for y in range(map_size.y):
			#Can we walk on this tile?
			var tile_position = Vector2(x, y)
			
			#Can we walk on it terrain-wise?
			var can_walk = get_cell_item(x, 0, y) in walkable_cells
			
			#Is there another tower there?
			can_walk = can_walk and _get_tower_at_location(x, y) == null
			
			#Can we walk here?
			if can_walk:
				walkable_tiles[tile_position] = true
				
	#Return these tiles
	_cached_walkable_tiles = walkable_tiles
	return walkable_tiles

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

func tile_on_path(x, y, path):
	#Is it in there?
	if path != null:
		if map_to_world(x, 0, y) in path:
			return true
			
	#Not on a path
	return false

func tile_on_paths(x, y, paths):
	#Just check them all
	for path in paths:
		if tile_on_path(x, y, path):
			return true
	
	#Nope
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
		var st = OS.get_ticks_msec()
		
		#Did we already have an answer?
		if _precalculated_can_build.has(position):
			return _precalculated_can_build[position]
		
		#Are we even on an existing path?
		if not tile_on_paths(x, y, _paths):
			#We don't need to worry about this one
			_precalculated_can_build[position] = true
			return true
		
		#Do the pathfinding, but give it an additional blocking tile
		var blocked_tiles = [Vector2(x, y)]
		var new_paths = _get_all_paths(blocked_tiles)
		var can_build = validate_paths(new_paths)
		_precalculated_can_build[position] = can_build
		
		#Return the result
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
	
	#We can remove this tower's location from the cached walkable locations
	_cached_walkable_tiles.erase(Vector2(x, y))

	
func remove_tower(x, y):
	#Remove a tower, return the to-be-destroyed tower
	
	#Is there a tower here?
	if _towers.has(x) and _towers[x].has(y):
		var tower = _towers[x][y]
		_towers[x].erase(y)
		
		#We can add this spot back to the walkable towers
		_cached_walkable_tiles[Vector2(x, y)] = true
		
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

