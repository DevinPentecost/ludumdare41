extends Node

var event_lock = false
var title_show = true

onready var cam = get_node("./Camera")
onready var env = cam.get_environment()
onready var skel = get_node("./shooter")
onready var title = get_node("./UI/title")
onready var anim = get_node("./shooter/AnimationPlayer")
onready var bottle1 = get_node("./bottle_start")
onready var bottle2 = get_node("./bottle_quit")
onready var tween = get_node("./tween")

onready var song = get_node("./sfx/song")
onready var wind = get_node("./sfx/wind")



onready var skel_rot = skel.rotation_degrees
onready var skel_rot_y = skel_rot.y

var rot_mag = 20
var cam_mag = 0.04
var cam_target = Vector3(-9.341848,1.267889,16.121799)
var tweentime = 3
var tweendelay = 0.08

var x1 = -9.340
var x2 = -9.310
var xx = 0.006
var y1 = 1.248
var yy = 0.014

func _ready():
	set_process(true)
	set_process_input(true)
	
	anim.play("idle")
	anim.get_animation("attack.loop").set_loop(false)


func _process(delta):
	pass

func bcheck(vx,vy):
	if vy > -0.5 and vy < 0.5:
		if vx > -0.7 and vx < -0.2:
			tween.interpolate_property(bottle1,"translation",bottle1.translation,bottle1.translation+Vector3(-1,3,10),tweentime/2,Tween.TRANS_LINEAR,Tween.EASE_IN,tweendelay)
			tween.interpolate_property(bottle1,"rotation_degrees",Vector3(0,0,0),Vector3(1000,200,0),tweentime/2,Tween.TRANS_LINEAR,Tween.EASE_IN,tweendelay)
			
			#change scene
			tween.interpolate_callback(self,tweentime/2,"startgame")
			tween.start()
			
		elif vx > 0.25 and vx < 0.7:
			tween.interpolate_property(bottle2,"translation",bottle2.translation,bottle2.translation+Vector3(1,3,10),tweentime,Tween.TRANS_LINEAR,Tween.EASE_IN,tweendelay)
			tween.interpolate_property(bottle2,"rotation_degrees",Vector3(0,0,0),Vector3(1000,200,0),tweentime/2,Tween.TRANS_LINEAR,Tween.EASE_IN,tweendelay)
			
			
			#quit here
			tween.interpolate_callback(self,tweentime/2,"quitgame")
			tween.start()
	
func _input(event):
	
	# quit with ESC
	#
	
	if not event_lock and event is InputEventMouse:
		var vp_size = get_viewport().size
		var vpx = vp_size.x
		var vpy = vp_size.y
		
		var mouse_pos = event.position
		var mx = mouse_pos.x
		var my = mouse_pos.y
		
		var relx = 2*(mx/vpx - 0.5)
		var rely = 2*(my/vpy - 0.5)
		
		
		if event is InputEventMouseButton:
				if event.button_index == BUTTON_LEFT and event.pressed == false:
					if title_show == true and not tween.is_active():
						#sfx.play("slurp")
						tween.interpolate_property(title,"modulate",Color(1,1,1,1),Color(1,1,1,0),tweentime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,0)
						tween.interpolate_property(cam,"translation",Vector3(-9.003917,1.884272,16.121799),cam_target,tweentime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,0)
						
						tween.interpolate_property(env,"dof_blur_far_amount",0,0.1,tweentime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,0)
						tween.interpolate_property(env,"dof_blur_near_amount",0.1,0.0,tweentime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,0)
						tween.interpolate_property(cam,"fov",8,16,tweentime,Tween.TRANS_QUAD,Tween.EASE_IN_OUT,0)
						tween.interpolate_property(wind,"volume_db",-15,-50,tweentime,Tween.TRANS_LINEAR,Tween.EASE_IN,0)
						
						tween.interpolate_callback(self,tweentime,"switchtitle")
						
						
						# fade to show bottles
						song.play()
						
						tween.start()
						
						anim.play("attack.init",-1.0,0.3)
					elif title_show == false:
						anim.play("attack.loop",-1.0,1.0)
						anim.animation_set_next("attack.loop","attack.idle")
						bcheck(relx,rely)
					
		elif event is InputEventMouseMotion and not title_show:

			
			
			var relr = skel_rot + Vector3(0,relx*rot_mag-rot_mag/4,0)
			skel.rotation_degrees = relr
			var relcam = cam_target + Vector3(cam_mag*relx,-cam_mag*rely/2,0)
			cam.translation = relcam
			
			
			
func switchtitle():
	title_show = false
	tween.stop_all()
func startgame():
	get_tree().change_scene("res://SCENES/test/CalebSandbox.tscn")
func quitgame():
	get_tree().quit()