extends Spatial

### THIS IS WHERE TOWER INFO GOES! ###

export(String) var towerType = "abstract"
export(String) var bulletPath = "res://SCENES/Bullets/Bullet.tscn"
export(String) var towerIcon = "res://UISPRITES/cursorBronze.png"




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