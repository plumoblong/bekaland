extends Sprite3D
class_name RotatingSprite

var _camera : Camera3D
var _facing : Node3D

@export var color : Color = Color.WHITE
@export var damage_color : Color = Color(1.0, 0.4, 0.4, 1.0)
@export var death_anim_final_color : Color = Color(1.0, 0.4, 0.4, 1.0)
@export var flip : bool = false

@export var side_angle_min : float = 45.0
@export var side_angle_max : float = 135.0

var _progress_death_anim : float = 0.0
var _active_death_anim : bool = false

const FRAME_FRONT := 0
const FRAME_BACK := 1
const FRAME_SIDE := 2

func _ready() -> void:
	_facing = get_parent()
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	visibility_range_end = 300.0
	visibility_range_end_margin = 10.0
	visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_camera = get_viewport().get_camera_3d()

func _process(delta: float) -> void:
	if _camera == null or _facing == null: return
	
	if _active_death_anim:
		_progress_death_anim += delta
		scale = Vector3.ONE * (1.0 - _progress_death_anim)
	else:
		_progress_death_anim = 0.0
		
	var f : Vector3 = -_facing.global_transform.basis.z
	f.y = 0.0
	f = f.normalized()

	var c : Vector3 = _camera.global_transform.origin - _facing.global_transform.origin
	c.y = 0.0
	c = c.normalized()

	var a : float = rad_to_deg(f.angle_to(c))

	if a < side_angle_min:
		frame = FRAME_FRONT
	elif a > side_angle_max:
		frame = FRAME_BACK
	else:
		frame = FRAME_SIDE if hframes > 2 else FRAME_FRONT

	var r : Vector3 = _camera.global_transform.basis.x
	flip_h = f.dot(r) < 0.0
	
	
	
func damage_anim(time : float = 0.1) -> void:
	modulate = damage_color
	await get_tree().create_timer(time).timeout
	modulate = color
	
func death_anim() -> void:
	_active_death_anim = true
