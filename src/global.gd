extends CanvasLayer
class_name Global

@onready var debug_label : Label = get_node("Control/DebugLabel")
@onready var loading_screen : LoadingScreen = get_node("LoadingScreen")
@onready var _alert : Label = get_node("Alert")

var game : Game

var time : float = 0.0

var current_debug_draw : int = 0
var show_fps : bool = false
var debug_mode : bool = false

var _is_debug_build : bool = false
var _host_os : String =""

const GROUP_DESTROYABLE : StringName = "Destroyable"
const GROUP_ENTITY : StringName = "Entity"
const GROUP_PICKUP : StringName = "Pickup"

const ALERT_SPEED : float = 0.2

var _alert_alpha : float = 0.0

func set_init_flags() -> void:
	var h : Array[bool] = [OS.has_feature("pc"), OS.has_feature("mobile"), OS.has_feature("web")]
	match h:
		[false, false, true]:
			_host_os = "web"
		[false, true, false]:
			_host_os = "mobile"
		_:
			_host_os = "pc"
		
	_is_debug_build = OS.has_feature("debug")

func _process(delta: float) -> void:
	_handle_fullscreen()
	time += delta
	if _alert_alpha > 0.0:
		_alert_alpha -= delta * ALERT_SPEED
		
	_alert.modulate.a = _alert_alpha
	_update_debug()

func _update_debug() -> void:
	if not _is_debug_build: return
	_switch_render_mode()
	
	debug_label.text = (
		str(int(Engine.get_frames_per_second())) + " FPS\n" + \
		"Render Mode " + str(current_debug_draw as Viewport.DebugDraw)
	)
	
	if Input.is_action_just_pressed("debug_show"):
		debug_mode = not debug_mode
	
	if Input.is_action_just_pressed("show_fps"):
		show_fps = not show_fps
		
	debug_label.visible = show_fps

func _handle_fullscreen() -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if get_window().mode != Window.MODE_FULLSCREEN:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED

func _switch_render_mode() -> void:
	if Input.is_action_just_pressed("debug_render_mode"):
		if current_debug_draw < 4:
			current_debug_draw += 1
		else:
			current_debug_draw = 0
	
	get_viewport().debug_draw = current_debug_draw
	
func normal_to_euler(normal: Vector3, up_reference: Vector3 = Vector3.FORWARD) -> Vector3:
	# Build an orthonormal basis where Y aligns with the normal
	var up: Vector3 = normal.normalized()

	# Pick a reference direction that isn't parallel to the normal
	var reference: Vector3 = up_reference
	if abs(up.dot(reference)) > 0.99:
		reference = Vector3.RIGHT

	var right: Vector3 = reference.cross(up).normalized()
	var forward: Vector3 = up.cross(right).normalized()

	var basis := Basis(right, up, forward)
	return basis.get_euler()

static func choose_from_chance(values : Dictionary):
	var weighted_list : Array = []
	for key in values.keys():
		var weight := maxi(values[key], 1)
		for i in weight:
			weighted_list.append(key)
	return weighted_list[randi() % weighted_list.size()]

func set_alert(text : String = "Something is hnapening", color : Color = Color.MAGENTA) -> void:
	_alert.text = text
	_alert.modulate = color
	_alert_alpha = 1.0
