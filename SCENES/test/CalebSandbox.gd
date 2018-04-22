extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	var overlay = get_node("2D_UI/UiOverlay")
	overlay.setAvailable("Kisser", true)
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_GameController_damage_taken():
	get_node("lifeLost").visible = true
	pass # replace with function body


func _on_Button_pressed():
	get_node("lifeLost").visible = false
	pass # replace with function body
