extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

onready var baddieScene = load("res://SCENES/GameController/BaddieType.tscn")

export var numBaddies = 1
export var baddieSpawnDelayMs = 3000 # Milliseconds between spawns
export var baddieStatsMultiplier = 1
export var baddieHealth = 100 # Weakest
export var baddieSpeed = 100 # Slowest

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
	newBaddie.baddieHealth = baddieHealth * baddieStatsMultiplier
	newBaddie.baddieSpeed = baddieSpeed
	return newBaddie