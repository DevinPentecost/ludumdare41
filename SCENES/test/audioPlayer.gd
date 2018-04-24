extends AudioStreamPlayer

export(AudioStreamSample) var nextWaveSFX
export(AudioStreamSample) var loseLifeSFX



# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func play_next_wave():
	play_sound(nextWaveSFX)

func play_lose_life():
	play_sound(loseLifeSFX)

func play_sound(sound):
	if playing:
		return
	stream = sound
	play()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
