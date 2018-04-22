extends Spatial

export(String) var towerType = null
export(NodePath) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"

#onready var __bulletScene = 

var bulletSpawnOffset = Vector3(0.0,0.0,0.0)

func canShoot(baddie):
	return true

func shootAt(baddie):
	if (!canShoot(baddie)):
		return
	var bullet = __createBullet()
	print (_description() + "shooting at " + str(baddie))
	bullet.shootAt(baddie)

func __createBullet():
	var nBullet = (load(bulletPath)).instance()
	#todo: offest should be based on current facing
	nBullet.transform.origin = self.global_transform.origin + bulletSpawnOffset
	
	return nBullet

func _ready():
	print("new "+_description())
	pass

func _description():
	return self.towerType+" tower at " + str(self.global_transform.origin)