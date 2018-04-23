extends Spatial

### THIS IS WHERE TOWER INFO GOES! ###
export(NodePath) var gameController = null
export(String) var towerType = "abstract"
export(String) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"
export(String) var towerIcon = "res://UISPRITES/cursorBronze.png"
export(int) var autoAttackDelayMs = 1000 # One attack, wait a second
export(int) var manualAttackDelayMs = 500 # One attack, wait half a second


var timeSinceAutoAttackS = 0.0
var autoAttackReady = false
var timeSinceManualAttackS = 0.0
var manualAttackReady = false

func _process(delta):
	incrementAttackTimers(delta)
	# If we are ready to attack lets ask the controller for a baddie?
	if (manualAttackReady):
		var baddieList = baddieList
		var closestBaddie = null
		var myLocation = global_transform.origin
		var clostestDistanceSquared = null
		for baddie in baddieList:
			var distance = myLocation.distance_squared_to(baddie.global_transform.origin)
			if clostestDistanceSquared == null:
				clostestDistanceSquared = distance
				closestBaddie = baddie
			if clostestDistanceSquared < distance:
				# Closer!
				clostestDistanceSquared = distance
				closestBaddie = baddie
			
		if closestBaddie != null:
			attemptManualAttack(closestBaddie)
	pass

func incrementAttackTimers(delayS):
	timeSinceAutoAttackS += delayS
	timeSinceManualAttackS += delayS
	
	if (timeSinceAutoAttackS * 1000 > autoAttackDelayMs):
		autoAttackReady = true
	
	if (timeSinceManualAttackS * 1000 > manualAttackDelayMs):
		manualAttackReady = true

func attemptManualAttack(baddie):
	if manualAttackReady == true:
		shootAt(baddie)
		manualAttackReady = false
		timeSinceManualAttackS = 0
		
func attemptAutoAttack(baddie):
	if autoAttackReady == true:
		shootAt(baddie)
		autoAttackReady = false
		timeSinceAutoAttackS = 0

func canShoot(baddie):
	return true

func shootAt(baddie):
	if (!canShoot(baddie)):
		return
	var bullet = __createBullet()
	print (_description() + " shooting at " + str(baddie) + " with " + str(bullet))
	bullet.shootAt(baddie)

func __createBullet():
	var nBullet = (load(bulletPath)).instance()
	self.add_child(nBullet)
	#todo: orient to this spatial's facing
	nBullet.global_transform.origin = self.global_transform.origin
	return nBullet


func _description():
	return str(self.towerType) +" tower at " + str(self.global_transform.origin)