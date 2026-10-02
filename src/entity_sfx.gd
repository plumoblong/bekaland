extends AudioStreamPlayer3D
class_name EntitySFX

@export var health : Health
@export var idle_sound_timer : Timer

@export var idle_sounds : Array[AudioStream]
@export var hurt_sounds : Array[AudioStream]
@export var die_sounds : Array[AudioStream]

@export var idle_pitch_range : Vector2 = Vector2(1.0, 1.0)
@export var idle_time_range : Vector2 = Vector2(5.0, 15.0)
@export var hurt_pitch_range : Vector2 = Vector2(1.0, 1.0)
@export var die_pitch_range : Vector2 = Vector2(1.0, 1.0)

enum SoundType {
	IDLE,
	HURT,
	DIE,
}

func _ready() -> void:
	attenuation_filter_cutoff_hz = 20500.0
	doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	health.damaged.connect(_play_hurt_sound)
	health.died.connect(_play_die_sound)
	idle_sound_timer.timeout.connect(_play_idle_sound)
	idle_sound_timer.start(5.0)
	
func start_sound(type : SoundType, pitch : float = 1.0, distance : float = 50.0) -> void:
	stream = _pick_stream(type)
	
	if stream == null:
		print(type, " sound list is empty")
		return
	
	max_distance = distance
	max_db = 0.0
	
	match type:
		SoundType.HURT:
			_pause_timer()
			pitch_scale = randf_range(hurt_pitch_range.x, hurt_pitch_range.y) * pitch
		SoundType.DIE:
			idle_sound_timer.paused = true
			pitch_scale = randf_range(die_pitch_range.x, die_pitch_range.y) * pitch
		_:
			pitch_scale = randf_range(idle_pitch_range.x, idle_pitch_range.y) * pitch
			
	play()

func _pause_timer() -> void:
	idle_sound_timer.paused = true
	await get_tree().create_timer(4.0).timeout
	idle_sound_timer.paused = false

func _play_hurt_sound(_value : float, _type : Health.DamageType) -> void:
	start_sound(SoundType.HURT)
	
func _play_idle_sound() -> void:
	start_sound(SoundType.IDLE)
	idle_sound_timer.start(randf_range(idle_time_range.x, idle_time_range.y))

func _play_die_sound() -> void:
	start_sound(SoundType.DIE)

func _pick_stream(type : SoundType) -> AudioStream:
	
	var a : AudioStream
	
	match type:
		SoundType.HURT:
			if hurt_sounds.is_empty():
				return null
			a = hurt_sounds.pick_random()
			
		SoundType.DIE:
			if die_sounds.is_empty():
				return null
			a = die_sounds.pick_random()
		_:
			if idle_sounds.is_empty():
				return null
			a = idle_sounds.pick_random()
			
	return a
