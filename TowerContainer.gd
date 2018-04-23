extends Spatial

export(String) var towerType = "abstract"
export(NodePath) var bulletPath = NodePath("res://SCENES/Bullets/Bullet.tscn")
export(String) var towerIcon = str("res://UISPRITES/cursorBronze.png")
var buttonPath = NodePath("res://SCENES/Overlay/TowerButton.tscn")

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
	#todo: orient to this spatial's facing
	nBullet.global_transform.origin = self.global_transform.origin
	self.add_child(nBullet)
	return nBullet

func _ready():
	print("new "+_description())

func _description():
	return str(self.towerType) +" tower at " + str(self.global_transform.origin)