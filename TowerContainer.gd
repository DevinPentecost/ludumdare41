extends Spatial

### THIS IS WHERE TOWER INFO GOES! ###
export(String) var towerType = "abstract"
export(String) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"
export(String) var towerIcon = "res://UISPRITES/cursorBronze.png"
export(int) var autoAttackDelayMs = 5000 # One attack, wait this many millisecond
export(int) var manualAttackDelayMs = 1000 # One attack, wait this many second


var timeSinceAutoAttackS = 0.0
var autoAttackReady = true
var timeSinceManualAttackS = 0.0
var manualAttackReady = true

var gameController = null

func _process(delta):
	incrementAttackTimers(delta)
	# If we are ready to attack lets ask the controller for a baddie?
	if (manualAttackReady):
		var baddieList = gameController.baddieList
		var closestBaddie = null
		var myLocation = global_transform.origin
		var clostestDistanceSquared = null
		
		for baddie in baddieList:
			if baddie.visible == false:
				continue
			
			var distance = myLocation.distance_squared_to(baddie.global_transform.origin)
			if clostestDistanceSquared == null:
				clostestDistanceSquared = distance
				closestBaddie = baddie
				continue
			if distance < clostestDistanceSquared:
				# Closer!
				clostestDistanceSquared = distance
				closestBaddie = baddie
				continue
			
		if closestBaddie != null:
			attemptAutoAttack(closestBaddie)
	pass

func incrementAttackTimers(delayS):
	#print("timeSinceAutoAttackS" + str(timeSinceAutoAttackS))
	#print("timeSinceManualAttackS" + str(timeSinceAutoAttackS))
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
	#print (_description() + " shooting at " + str(baddie) + " with " + str(bullet))
	bullet.shootAt(baddie)

func __createBullet():
	var nBullet = (load(bulletPath)).instance()
	self.add_child(nBullet)
	#todo: orient to this spatial's facing
	nBullet.global_transform.origin = self.global_transform.origin
	return nBullet


func _description():
	return str(self.towerType) +" tower at " + str(self.global_transform.origin)