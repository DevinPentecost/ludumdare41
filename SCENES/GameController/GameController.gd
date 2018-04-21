extends Node

# Signals
signal level_started(levelNum)
signal level_finished(levelNum)
signal baddie_spawned()
signal damage_taken()
signal game_over()

# Nodes of interest
onready var spawner = get_node("Spawner")
onready var gridScene = null
onready var towerScene = null

# Complicated objects + lists
var currentLevel = null
var gameGrid = null
var baddieList = []
var towerList = []

# Simple Variables
var lastLevel = 0
var currentLevelIndex = 0
var suddenDeathMultiplier = 0
var kDelayBetweenLevelsSeconds = -1 #-30 # Negative to require a count-up to the next spawn
var timeSinceLastSpawnSeconds = 0

# Debug stuff
var testVector1 = Vector3(3, 0, 3)
var testVector2 = Vector3(3, 0, -3)
var testVector3 = Vector3(-3, 0, 3)
var testVector4 = Vector3(-3, 0, -3)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
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
		spawnNext(1)
	
	# I think thats all we care about!
	return

func isLevelFinished():
	# Have we started any levels?
	if currentLevelIndex == 0:
		# Game starts in a "finished level" state
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
		baddieList.append(newBaddie)
		add_child(newBaddie)
		var follower = newBaddie.get_node("WaypointFollower")
		follower.AppendWaypoint(testVector1)
		follower.AppendWaypoint(testVector2)
		follower.AppendWaypoint(testVector3)
		follower.AppendWaypoint(testVector4)
	pass
	
func _baddieDied(theBaddie):
	# Remove from the list
	baddieList.erase(theBaddie)
	remove_child(theBaddie)
	theBaddie.queue_free()
	# Emit an event?
	pass