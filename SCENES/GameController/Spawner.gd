extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var _levelInfo = null
var _numBaddiesLeftToSpawn = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

# Starts the next level with the number of baddies of the given type.
# Returns the number of leftover baddies from the last level
func startNextLevel(levelInfo):
	# Are we starting a new level too soon?
	var remainingBaddies = _numBaddiesLeftToSpawn
	
	# Nab level info
	_levelInfo = levelInfo
	_numBaddiesLeftToSpawn = levelInfo.numBaddies
	
	return remainingBaddies
	

# Determines if enough time has passed to spawn a new baddie
# True if enough time has passed, false otherwise
func timeForNextBaddie(timeSinceLastSpawnSeconds):
	# Has it been enough time?
	if (timeSinceLastSpawnSeconds * 1000) <= _levelInfo.baddieSpawnDelayMs:
		return false
	
	return true

# Generates a new baddie if there's a spawn left. Reduces the spawn counter appropriately
# Returns the instance of the baddie, or null if one could not be made
func giveMeABaddie(spawnGridLocation):
	# Are there any baddies to create?
	if _numBaddiesLeftToSpawn > 0:
		# Create one, potentially multiplying its stats
		var baddie = _levelInfo.createBaddieInstance(spawnGridLocation)
		# Decrement our counter
		_numBaddiesLeftToSpawn = _numBaddiesLeftToSpawn - 1
		# Return the baddie!
		return baddie
			
		
	
	# Getting here means we couldn't spawn anything!
	return null
	