extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var controller = $PlayerController
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var RUN_SPEED = 7.0

@export var mouse_sensibility = 800
@export var ladder_height_subtract = 1

var bobbing_amount = 0.05
var bobbing_speed = 10.0
var bobbing_timer = 0.0
var min_camera_x = deg_to_rad(-90)
var max_camera_x =  deg_to_rad(90)
var camera
var ladder_height = 0

enum PLAYER_MODES {
	WALK,
	LADDER
}
var current_mode := PLAYER_MODES.WALK

var tween

func _ready():
	camera = controller.camera
	var stream = $"../Enviroment/Wind".stream
	if stream is AudioStream:
		stream.loop = true
	$"../Enviroment/Wind".play()


func _physics_process(delta):
	match current_mode:
		PLAYER_MODES.WALK:
			walk_process(delta)
		PLAYER_MODES.LADDER:
			ladder_process(delta)

func walk_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_running = Input.is_action_pressed("Run")
	var current_speed = RUN_SPEED if is_running else SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)


		
		# Efecto de balanceo
	if direction and is_on_floor():
		bobbing_timer += delta * bobbing_speed
		var bob_offset = sin(bobbing_timer) * bobbing_amount
		controller.camera.transform.origin.y = bob_offset

		# Reproducir pasos
		if not $"../Enviroment/Walk".playing:
			$"../Enviroment/Walk".pitch_scale = randf_range(0.9, 1.1)
			$"../Enviroment/Walk".play()
	else:
		bobbing_timer = 0
		controller.camera.transform.origin.y = 0

		# Detener pasos
		if $"../Enviroment/Walk".playing:
			$"../Enviroment/Walk".stop()


	move_and_slide()

func ladder_process(_delta):
	
	if Input.is_action_just_pressed("Jump"):
		velocity.y = JUMP_VELOCITY
		set_player_mode(PLAYER_MODES.WALK)
		return
	
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveDown", "moveUp")
	var direction = (transform.basis * Vector3(0, input_dir.y,0)).normalized()
	if direction:
		velocity.y = direction.y * SPEED	
	else:
		velocity.y = move_toward(velocity.x, 0, SPEED)
	if position.y >= ladder_height - ladder_height_subtract and velocity.y > 0:
		velocity.y = 0
		
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and controller.can_move_camera:
		rotation.y -= event.relative.x / mouse_sensibility
		camera.rotation.x -= event.relative.y / mouse_sensibility
		camera.rotation.x = clamp(camera.rotation.x,min_camera_x,max_camera_x)

func set_player_mode(mode: PLAYER_MODES):
	current_mode = mode
	
func set_on_ladder(on_ladder, height,reference: Node3D):
	
	if on_ladder:
		velocity = Vector3(0,0,0)
		var ref_pos = reference.global_position
		var new_position = Vector3(ref_pos.x,position.y, ref_pos.z)
		tween = create_tween()
		
		tween.tween_property(self,"position",new_position,.2) 
		tween.tween_property(self,"quaternion",reference.quaternion,.2) 
		 
		
		
		velocity = Vector3(0,0,0)
	
		set_player_mode(PLAYER_MODES.LADDER)
		velocity = Vector3(0,0,0)
	
	else:
		set_player_mode(PLAYER_MODES.WALK)
	ladder_height = height
	
