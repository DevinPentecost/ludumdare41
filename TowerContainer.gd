extends Spatial

export(String) var towerType = null
export(NodePath) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"


func canShoot(baddie):
	return true

func shootAt(baddie):
	if (!canShoot(baddie)):
		return
	var bullet = __createBullet()
	print (_description() + "shooting at " + str(baddie) + " with " + str(bullet))
	bullet.shootAt(baddie)

func __createBullet():
	var nBullet = (load(bulletPath)).instance()
	#todo: orient to this spatial's facing
	nBullet.transform.origin = self.transform.origin
	
	return nBullet

func _ready():
	print("new "+_description())
	pass

func _description():
	return str(self.towerType) +" tower at " + str(self.transform.origin)