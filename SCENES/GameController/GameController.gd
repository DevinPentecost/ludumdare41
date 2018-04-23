extends Node

# Signals
signal level_started(levelNum)
signal level_finished(levelNum)
signal baddie_spawned()
signal damage_taken()
signal game_over()

export(NodePath) var gameGridPath
export(NodePath) var uiOverlayPath
export(NodePath) var primaryCameraPath

# Nodes of interest
onready var spawner = get_node("Spawner")
onready var gameGrid = get_node(gameGridPath)
onready var uiOverlay = get_node(uiOverlayPath)
onready var primaryCamera = get_node(primaryCameraPath)
onready var towerScene = null

# Complicated objects + lists
var currentLevel = null
var baddieList = []
var towerList = []

# Simple Variables
var lastLevel = 0
var currentLevelIndex = 0
var suddenDeathMultiplier = 0
var kDelayBetweenLevelsSeconds = -1 #-30 # Negative to require a count-up to the next spawn
var timeSinceLastSpawnSeconds = 0

# Debug stuff
var baddiePath2D = []

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	gameGrid.connect("new_paths_ready", self, "_handleNewPaths")
	gameGrid.connect("tileClicked", self, "__handleTileClick")
	uiOverlay.connect("TowerPicked", self, "__handleUiPick")
	pass

func _process(deltaSeconds):
	# Called every frame. Delta is time since last frame.
	# Update game logic here.
	
	# Is the level finished?
	var levelFinished = isLevelFinished()
	if levelFinished == true:
		# Increment and start the level
		currentLevelIndex = currentLevelIndex + 1
		startLevel(currentLevelIndex)
		# TODO: Add special effects to the levels?
		timeSinceLastSpawnSeconds = kDelayBetweenLevelsSeconds
		return
	
	# Is it time to spawn a unit?
	timeSinceLastSpawnSeconds = timeSinceLastSpawnSeconds + deltaSeconds
	if spawner.timeForNextBaddie(timeSinceLastSpawnSeconds):
		timeSinceLastSpawnSeconds = 0
		spawnNext(baddiePath2D[0][0])
	
	# I think thats all we care about!
	return

func isLevelFinished():
	# Have we started any levels?
	if currentLevelIndex == 0:
		# Game starts in a "finished level" state
		# Always do pathing at the start of the game
		gameGrid.refresh_pathfinding()
		return true
	
	# Are there any baddies left to spawn?
	if spawner._numBaddiesLeftToSpawn > 0:
		return false
	
	# Are there any baddies left alive?
	if baddieList.size() != 0:
		return false
	
	# Nothing told us that we aren't done!
	return true

func startLevel(levelNum):
	
	var level = get_node("Levels/Level" + String(levelNum))
	if level == null:
		# No level present! Make it harder and start over
		currentLevelIndex = 1
		suddenDeathMultiplier = suddenDeathMultiplier + levelNum
		startLevel(currentLevelIndex)
		return
		
	
	# Make the level harder if we are in sudden death
	level.baddieStatsMultiplier = level.baddieStatsMultiplier + suddenDeathMultiplier
	
	# We have the level, lets pass its info into the spawner
	var leftoverBaddies = spawner.startNextLevel(level)
	pass

func spawnNext(spawnGridLocation):
	# Get the next baddie from the spawner
	var newBaddie = spawner.giveMeABaddie(spawnGridLocation)
	if newBaddie != null:
		# We need to track this baddie
		newBaddie.connect("just_died", self, "_baddieDied", [newBaddie])
		newBaddie.connect("escaped", self, "_baddieEscaped", [newBaddie])
		baddieList.append(newBaddie)
		add_child(newBaddie)
		var follower = newBaddie.get_node("WaypointFollower")
		for path in baddiePath2D:
			for step in path:
				follower.AppendWaypoint(step)
		newBaddie.connect("baddieClicked", self, "__handleBaddieClick")
	pass
	
func _baddieDied(theBaddie):
	if (theBaddie != null):
		# Remove from the list
		baddieList.erase(theBaddie)
		#remove_child(theBaddie)
		#theBaddie.queue_free()
		var killDown = load("res://SCENES/GameController/DelayKill.tscn").instance()
		theBaddie.add_child(killDown)
	# Emit an event?
	pass

func _baddieEscaped(theBaddie):
	# Remove from the list
	emit_signal("damage_taken")
	
	baddieList.erase(theBaddie)
	remove_child(theBaddie)
	theBaddie.queue_free()
	pass

func _handleNewPaths(pathList):
	if baddiePath2D != null:
		baddiePath2D.clear()
	
	for path in pathList:
		baddiePath2D.append(path)
		
	# Existing baddies need this new path!
	# Just have them find the closest one...
	# for each baddie
	for baddie in baddieList:
		# Get the follower and clear the waypoints
		var follower = baddie.get_node("WaypointFollower")
		follower.ClearWaypoints(false)
		
		# find the index of the closest waypoint
		
		var closestPathIndex = null
		var closestWaypointIndex = null
		var closestWaypointDistance = null
		# number of paths
		for pathIndex in range(0, baddiePath2D.size()):
		# for each path
			for pointIndex in range(0, baddiePath2D[pathIndex].size()):
				#var pathPosition = Vector3(baddiePath2D[pathIndex][pointIndex].x, baddiePath2D[pathIndex][pointIndex].y, baddiePath2D[pathIndex][pointIndex].z)
				var pathPosition = baddiePath2D[pathIndex][pointIndex]
				var distance = baddie.global_transform.origin.distance_squared_to(pathPosition)
				if closestWaypointIndex == null:
					closestPathIndex = pathIndex
					closestWaypointIndex = pointIndex
					closestWaypointDistance = distance
					continue
					
				if distance < closestWaypointDistance:
					closestPathIndex = pathIndex
					closestWaypointIndex = pointIndex
					closestWaypointDistance = distance
					continue
		
		if closestWaypointIndex != null:
			for pathIndex in range(closestPathIndex, baddiePath2D.size()):
				for pointIndex in range(closestWaypointIndex, baddiePath2D[pathIndex].size()):
					follower.AppendWaypoint(baddiePath2D[pathIndex][pointIndex])
	pass
	
func _input(event):
   # Mouse in viewport coordinates
   #if event is InputEventMouseButton:
   #    print("Mouse Click/Unclick at: ", event.position)
   #elif event is InputEventMouseMotion:
   #    print("Mouse Motion at: ", event.position)
	pass

func __handleUiPick(towerString):
	print("display tooltip for " + str(towerString))
	pass

func __handleBaddieClick(baddie):
	for T in self.towerList:
		T.find_node("Tower", true, true).attemptManualAttack(baddie)

func __handleTileClick(pos):
	if (uiOverlay.currentTower == null):
		return
	
	# put a tower at the location
	print("please put a "+uiOverlay.currentTower+" tower at grid: " + str(pos.tile_position) + " world: " + str(pos.transform.origin) )
	var new_tower = __createTower(uiOverlay.currentTowerPath, pos)
	
	#uiOverlay.unselectAll()
	
	# Finally, tell the game grid that a tower is present -- it doesn't care what flavor
	var towerTile = {}
	towerTile.x = pos.tile_position.x
	towerTile.y = pos.tile_position.z
	gameGrid.add_tower(pos.tile_position.x, pos.tile_position.z, new_tower)
	
	# Re-do pathing
	gameGrid.clear_paths()
	gameGrid.refresh_pathfinding()

func __createTower(towerPath, pos):
	#var towerFolder = "res://SCENES/Towers/*"
	#TODO: create instance of tower based on the string type?
	
	var towerScene = load(towerPath)
	var nTower = towerScene.instance()
	nTower.get_node("Tower").gameController = self
	self.add_child(nTower)
	# todo: this should be global position based on grid pos
	nTower.transform.origin = pos.transform.origin
	
	towerList.append(nTower)
	#add_child(nTower)
	return nTower

# End of file
