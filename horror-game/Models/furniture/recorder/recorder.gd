extends Node3D

# Usamos @onready para obtener una referencia al nodo AudioRadio cuando la escena esté lista
@onready var audio_radio: AudioStreamPlayer3D = $AudioRadio
@onready var audio_interference_radio: AudioStreamPlayer3D = $AudioInterferenceRadio

var interference_plays_remaining = 0 # Contador de repeticiones de interferencia

func interact():
	# --- Reproducir el audio ---
	if audio_radio and !audio_radio.playing: # Verifica que el nodo exista y que no esté ya reproduciendo
		audio_radio.play()
		
		if !audio_interference_radio.playing and interference_plays_remaining <=0:
				interference_plays_remaining = 3 # Inicia el contador a 4 repeticiones
				audio_interference_radio.play()
	# --- Fin del cambio ---
func _on_audio_interference_radio_finished() -> void:
	interference_plays_remaining -= 1 #Si el audio finzalizo lo reproduce hasta que el contador es 0
	if interference_plays_remaining > 0:
		audio_interference_radio.play()
