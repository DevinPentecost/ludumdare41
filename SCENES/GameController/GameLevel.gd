extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

enum ExtraEffects{
	eExtraEffects_faster
	eExtraEffects_tough
	eExtraEffects_powerDrain
}

onready var baddieScene = load("res://SCENES/GameController/Baddie.tscn")

export var numBaddies = 1
export var baddieSpawnDelayMs = 3000 # Milliseconds between spawns
export var baddieHealth = 100 # Weakest
export var baddieSpeed = 1 # Slowest
export var baddiePowerDrain = 0 # No drain effect

var kMinimumMultiplierValue = 1
var baddieStatsMultiplier = kMinimumMultiplierValue
var extraEffectsList = []

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func createBaddieInstance(gridLocation):
	var newBaddie = baddieScene.instance()
	newBaddie.transform.origin = gridLocation
	print("New Baddie!")
	newBaddie.baddieHealth = baddieHealth
	newBaddie.baddieSpeed = baddieSpeed
	
	# Apply any special effects
	for extraEffect in extraEffectsList:
		if (extraEffect == eExtraEffects_faster):
			newBaddie.baddieSpeed += 50
		if (extraEffect == eExtraEffects_tough):
			newBaddie.baddieHealth += 50
		if (extraEffect == eExtraEffects_powerDrain):
			newBaddie.powerDrain += 1
	
	# Apply the multiplier once we are done
	newBaddie.baddieHealth *= baddieStatsMultiplier
	newBaddie.baddieHealth = max(newBaddie.baddieHealth, 2)
	newBaddie.baddieSpeed *= max(kMinimumMultiplierValue, baddieStatsMultiplier / 10)
	newBaddie.powerDrain *= max(kMinimumMultiplierValue, baddieStatsMultiplier / 10)
	return newBaddie