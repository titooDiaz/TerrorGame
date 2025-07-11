extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var controller = $PlayerController
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var RUN_SPEED = 7.0

@export var mouse_sensibility = 800
@export var ladder_height_subtract = 1

# detector radio

@onready var SeeCast3D: RayCast3D = $PlayerController/Head/Camcorder/SeeCast3D # ¡Asegúrate que esta ruta sea correcta para tu RayCast3D!
@onready var interact_label: Label = $PlayerController/Head/Camcorder/SeeCast3D/CanvasLayer/BoxContainer/LabelE

@export var INTERACTION_DISTANCE: float = 2.5 # <-- ¡NUEVO! Distancia máxima para interactuar

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

	# Esperar 10 segundos y cambiar de escena
	change_scene_after_delay()

func change_scene_after_delay() -> void:
	await get_tree().create_timer(10.0).timeout
	var new_scene = load("res://levels/city.tscn")
	if new_scene:
		get_tree().change_scene_to_packed(new_scene)
	else:
		print("⚠️ La escena no se pudo cargar. Verifica el path.")




func _physics_process(delta):
	# --- Inicio de la Lógica de Detección de Interacción ---
	var is_looking_at_interactable_and_close = false

	if SeeCast3D.is_colliding():
		var collider = SeeCast3D.get_collider() # Obtiene el nodo que el rayo golpeó

		# Verificar si el objeto golpeado es un StaticBody3D (o el tipo de tu radio)
		if collider and (collider.name == "radio"): # Puedes añadir más condiciones si necesitas diferenciar objetos
			# Calcular la distancia entre el jugador y el objeto detectado
			# Usamos global_position para obtener las coordenadas en el mundo
			var distance_to_collider = global_position.distance_to(collider.global_position)

			# Si está cerca Y el rayo lo está mirando
			if distance_to_collider <= INTERACTION_DISTANCE:
				is_looking_at_interactable_and_close = true
				# Opcional: Si quieres interactuar al presionar "Interactar"
				if Input.is_action_just_pressed("Interact"):
					print("¡Interaccionando con el radio!")
					
					if collider.has_method("interact"):
						collider.interact()
					else:
						print("Error: El objeto '", collider.name, "' no tiene la función 'interact()'.")
					# --- Fin del cambio ---

	# Mostrar u ocultar la LabelE de la UI del jugador
	interact_label.visible = is_looking_at_interactable_and_close # <-- ¡CAMBIO CLAVE AQUÍ!
	# --- Fin de la Lógica de Detección de Interacción ---
	
	match current_mode:
		PLAYER_MODES.WALK:
			walk_process(delta)
		PLAYER_MODES.LADDER:
			ladder_process(delta)

func walk_process(delta):
	var anim_player = null

	if is_instance_valid($man):
		anim_player = $man.get_node_or_null("AnimationPlayer")

	if not anim_player:
		return

	# Activar loop solo una vez (idealmente haz esto en _ready())
	for anim_name in ["Rig|idle", "Rig|walk", "Rig|run"]:
		if anim_player.has_animation(anim_name):
			anim_player.get_animation(anim_name).loop = true

	# Dirección y entrada
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Aplica gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if anim_player.has_animation("Rig|jump"):
			anim_player.play("Rig|jump")

	# Estado de movimiento
	var is_running = Input.is_action_pressed("Run")
	var is_crouching = Input.is_action_pressed("Crouch")
	var is_moving_backwards = input_dir.y < 0

	var current_speed = SPEED
	if is_crouching:
		current_speed = 1.5
	elif is_running:
		current_speed = RUN_SPEED
	elif is_moving_backwards:
		current_speed = SPEED * 0.6

	# Rotar el cuerpo según la cámara en el eje Y
	if direction:
		var target_rot = controller.camera.global_transform.basis.get_euler().y
		$man.rotation.y = lerp_angle($man.rotation.y, target_rot, delta * 10.0)

	# Movimiento horizontal
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Animaciones según estado
	var next_anim = ""

	if not is_on_floor():
		next_anim = "Rig|jump"
	elif direction:
		if is_running:
			next_anim = "Rig|run"
		else:
			next_anim = "Rig|walk"

	else:
		next_anim = "Rig|idle"

	if anim_player.has_animation(next_anim) and anim_player.current_animation != next_anim:
		anim_player.play(next_anim)

	# Bobbing (cabeceo)
	if direction and is_on_floor():
		bobbing_timer += delta * bobbing_speed
		var bob_offset = sin(bobbing_timer) * bobbing_amount
		controller.camera.transform.origin.y = bob_offset

		if not $"../Enviroment/Walk".playing:
			$"../Enviroment/Walk".pitch_scale = randf_range(1.0, 1.2) if is_running else randf_range(0.9, 1.1)
			$"../Enviroment/Walk".volume_db = -2 if is_running else -6
			$"../Enviroment/Walk".play()
	else:
		bobbing_timer = 0
		controller.camera.transform.origin.y = 0
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
