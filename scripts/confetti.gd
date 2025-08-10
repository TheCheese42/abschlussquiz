extends CanvasLayer
class_name Confetti

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

@export var position: Vector2 = Vector2.ZERO


func _ready() -> void:
	gpu_particles_2d.position = position
	gpu_particles_2d.one_shot = true


func _on_gpu_particles_2d_finished() -> void:
	queue_free()
