extends Node2D

@export var velocidad: float = 100.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play("walk_down")
	sprite.stop()
	sprite.frame = 0


func _process(delta: float) -> void:
	var direccion := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if direccion == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 0
		return

	position += direccion * velocidad * delta

	var animacion: String

	if abs(direccion.x) > abs(direccion.y):
		animacion = "walk_right" if direccion.x > 0 else "walk_left"
	else:
		animacion = "walk_down" if direccion.y > 0 else "walk_up"

	if sprite.animation != animacion:
		sprite.play(animacion)
	elif not sprite.is_playing():
		sprite.play()
