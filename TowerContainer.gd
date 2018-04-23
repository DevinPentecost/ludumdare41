extends Spatial

### THIS IS WHERE TOWER INFO GOES! ###
export(String) var towerType = "abstract"
export(String) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"
export(String) var towerIcon = "res://UISPRITES/cursorBronze.png"
export(int) var autoAttackDelayMs = 5000 # One attack, wait this many millisecond
export(int) var manualAttackDelayMs = 1000 # One attack, wait this many second

onready var anim = get_node("../Model/AnimationPlayer")
onready var model = get_node("../Model")

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
			attemptManualAttack(closestBaddie)
		else:
			anim.play("idle")
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
		
		var tower_angle = angle_calc(global_transform.origin,baddie.global_transform.origin)
		model.rotation_degrees = Vector3(0,tower_angle,0)
		
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
	elif not anim.is_playing():
		anim.play("attack.init")
		anim.play("attack.init")
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
	
func angle_calc(a,b):
	var angle = Vector2(a.x, a.y).angle_to(Vector2(b.x, b.z))
	#var a2 = rad2deg(atan(-(b.z-a.z)/(b.x-a.x)))+90 #This causes divide by 0 errors

	return angle