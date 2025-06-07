extends Node3D

@onready var animatespider = $spider/AnimationPlayer
@onready var animatebutterflies = $"../Enviroment/butterflies/CollisionShape3D/butterflies/AnimationPlayer"

func _ready():
	animatespider.play("Armature|Armature|ArmatureAction")
	animatebutterflies.play("Take 001")
	animatebutterflies.get_animation("Take 001").loop = true
