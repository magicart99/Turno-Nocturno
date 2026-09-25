extends CharacterBody2D

@export var velocidad: float = 120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pasos: AudioStreamPlayer2D = $Pasos

var ultima_direccion: String = "down"
var tiempo_paso: float = 0.0
var siguiente_paso: int = 0

var sonidos_pasos: Array[AudioStream] = [
	preload("res://audio/01-footstep.ogg"),
	preload("res://audio/02-footstep.ogg")
]

func _physics_process(delta: float) -> void:
	var direccion := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direccion * velocidad
	move_and_slide()

	if direccion == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 0
		tiempo_paso = 0.0
		return

	if abs(direccion.x) > abs(direccion.y):
		ultima_direccion = "right" if direccion.x > 0 else "left"
	else:
		ultima_direccion = "down" if direccion.y > 0 else "up"

	if sprite.animation != ultima_direccion:
		sprite.play(ultima_direccion)
	elif not sprite.is_playing():
		sprite.play()

	tiempo_paso -= delta
	if tiempo_paso <= 0.0:
		pasos.stream = sonidos_pasos[siguiente_paso]
		pasos.play()
		siguiente_paso = (siguiente_paso + 1) % sonidos_pasos.size()
		tiempo_paso = 0.38
