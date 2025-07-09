extends Node3D
func _ready():
	$AnimationPlayer.play("snowfall")
	var stream = $"../../Enviroment/VoiceLevel2".stream
	$"../../Enviroment/VoiceLevel2".play()
