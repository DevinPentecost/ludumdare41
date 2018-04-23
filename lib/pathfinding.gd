const ADJACENT_POSITIONS = [[-1, 0], [1, 0], [0, -1], [0, 1]]
const DEBUG_PATH = "res://lib/pathfinding_debug/"

static func _build_step(g_score, f_score, point, parent):
	return {
		'g': g_score,
		'f': f_score,
		'pt': point,
		'parent': parent,
	}
	
static func FindPathTiles(start_position, end_position, walkable_tiles={}, max_attempts=9999):

	if end_position == Vector2(25, 25):
		pass

	#Open and closed tiles
	var start_tile = _build_step(0, 0, start_position, null)
	var open = {0: [start_tile]}
	var open_tiles = {start_position: start_tile}
	var closed_tiles = {}
	var prefix = OS.get_ticks_msec()
	
	#While we haven't run out of tiles...
	var previous_tile = null
	var step_count = 0
	while open:
		
		#DEBUG ONLY!
		#write_image(walkable_tiles, prefix, step_count, open_tiles, closed_tiles)
		
		if step_count > max_attempts:
			#Error!
			break
		
		step_count = step_count+1

		#Find the smallest score and remove it
		var current_tile = _get_smallest_f_tile(open, previous_tile)
		
		#Are we stuck?
		if current_tile == null:
			break
		
		previous_tile = current_tile
		var current_position = current_tile.pt

		#No longer consider this tile as we are currently doing so
		open[current_tile.f].erase(current_tile)
		open_tiles.erase(current_tile.pt)
		
		#Mark this X/Y as already used
		closed_tiles[current_tile.pt] = true
		
		#Did we reach the end?
		if current_tile.pt == end_position:
			#We did it
			var path = []
			while current_tile.parent:
				#Move to the next parent
				current_tile = current_tile.parent
				
				#Get the world position to move to
				path.append(current_tile.pt)
			
			#Return the path
			print("Pathfinding step count: ", step_count)
			path.invert()
			return path
		
		#Check adjacent tiles
		#for pos in __crappyPathRandom():
		for pos in ADJACENT_POSITIONS:
			#Get the adjacent tile
			var adjacent_tile = current_tile.pt + Vector2(pos[0], pos[1])
			
			if adjacent_tile == Vector2(25, 16):
				pass
			
			#Calculate some measurements
			var h = abs(adjacent_tile.x - end_position.x) + abs(adjacent_tile.y - end_position.y) #Distance to destination
			var new_g = current_tile.g + 1 #Total Steps
			var new_f = h + current_tile.g + 1 #Total nominal steps
			
			#Did we already close this one?
			if closed_tiles.has(adjacent_tile):
				continue
			
			#Did we already open this one?
			if open_tiles.has(adjacent_tile):
				#Update it with the new score?
				var old_tile = open_tiles[adjacent_tile]
				if old_tile.f > new_f:
					#Update everything
					open[old_tile.f].erase(old_tile)
				else:
					#Don't need to put bad work in
					continue
			
			#Is this a valid tile?
			if adjacent_tile in walkable_tiles:
				#Add it

				#Build the new tile
				var new_tile = _build_step(new_g, new_f, adjacent_tile, current_tile)
				
				#Do we have this score?
				if not open.has(new_f):
					open[new_f] = []
					
				
				#Add it
				open[new_f].insert(0, new_tile)
				open_tiles[adjacent_tile] = new_tile
				
			else:
				#Close the tile, we can't use it anyways
				closed_tiles[adjacent_tile] = true
	
	#Couldn't find a path
	#print("Failed to find a path after steps: ", step_count)
	return null

static func _get_smallest_f_tile(scored_tiles, previous_tile):
	#Max attempts to find it
	var max_attempts = 9999
	var current_attempt = 0
	
	#The tile we're currently voting for
	var best_tile = null
	
	#Search every score
	var f_values = scored_tiles.keys()
	f_values.sort()
	for f in f_values:
		
		#Get the tiles with this score
		var tiles = scored_tiles[f]
		
		#For each tile
		for tile in tiles:
			
			#Check attempts
			current_attempt += 1
			if best_tile and current_attempt > max_attempts:
				break
			
			#Do we not have a tile yet?
			if best_tile == null:
				best_tile = tile
				continue
			
			#Does this have the same parent and matching F score?
			if tile.f <= best_tile.f and tile.parent == previous_tile:
				#We prefer tiles at the head
				best_tile = tile
			
			#Does this have a better score?
			if tile.f < best_tile.f:
				best_tile = tile 
				
		#Did we find a best tile at this score?
		if best_tile:
			#pass
			break
			
	#Return the tile that we found
	#print("TOOK ATTEMPTS :",current_attempt)
	return best_tile
	
static func write_image(tiles, prefix, step, open, closed):
	var image = Image.new()
	image.create(30, 30, false, Image.FORMAT_RGBA8)
	image.lock()
	
	#Go over each pixel
	for position in tiles:
		var color = Color(1, 1, 1)
		if position in open:
			color = Color(0, 1, 0)
		elif position in closed:
			color = Color(1, 0, 1)
		
		image.set_pixel(position.x, position.y, color)
		
	image.unlock()
	var folder = DEBUG_PATH + str(prefix) + '/'
	var d = Directory.new()
	d.open(DEBUG_PATH)
	d.make_dir(folder)
	var path = folder + str(step) + '.png'
	image.save_png(path)
	
	pass