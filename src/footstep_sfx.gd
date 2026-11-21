extends AudioStreamPlayer3D
class_name FootstepSFX

@export var movement : Movement
@export var step_speed : float = 1.0
@export var volume : float = 0.3

func _ready() -> void:
	playing = true
	max_db = linear_to_db(volume)
	volume_db = linear_to_db(volume)

func _process(_delta: float) -> void:
	if not movement:
		return
	
	stream_paused = not movement.can_footstep_sfx_play()
	pitch_scale = movement.get_footstep_sfx_pitch() * step_speed
