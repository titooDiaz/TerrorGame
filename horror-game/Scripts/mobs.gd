extends Node3D

@onready var animatespider = $spider/spider/AnimationPlayer

func _ready():
	animatespider.play("Armature|Armature|ArmatureAction")
