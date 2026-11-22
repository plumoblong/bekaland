extends CanvasLayer
class_name Global

const VERSION : String = "❀"

@onready var debug_label : Label = get_node("Control/DebugLabel")
@onready var loading_screen : LoadingScreen = get_node("LoadingScreen")

@onready var _alert : AlertPopup = get_node("Alert")

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
const GROUP_CAN_PLACE : StringName = "CanPlace"
const GROUP_STATION : StringName = "Station"
const GROUP_INTERACT : StringName = "Interactable"

var world_seed : String = "" 

var is_starting_new_game : bool = false
var can_continue : bool = false

const VIEWPORT_SCALE : Vector2 = Vector2(640.0, 512.0)

const UI_BG_NORMAL_COLOR : Color = Color(0.0, 0.0, 0.0, 0.502)
const UI_BG_HOVER_COLOR : Color = Color(1.0, 1.0, 1.0, 0.502)
const UI_BG_SELECTED_COLOR : Color = Color(1.0, 1.0, 0.0, 0.502)
const UI_BG_TRANSITION_SPEED : float = 16.0
const UI_BG_COLOR_SPLIT : float = 0.33

const DUMMY_SLOT : InventorySlot = preload("res://data/item/dummy_slot.tres")

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
	override_max_fps(false)
	$Version.text = str(_G.VERSION) 

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		handle_fullscreen()
	time += delta
	#if _alert_alpha > 0.0:
		#_alert_alpha -= delta * ALERT_SPEED
		#
	#_alert.modulate.a = _alert_alpha
	_update_debug()

func _update_debug() -> void:
	if not _is_debug_build: return
	_switch_render_mode()
	
	debug_label.text = (
		str(int(Engine.get_frames_per_second())) + " FPS\n"
	)
	
	if Input.is_action_just_pressed("debug_show"):
		debug_mode = not debug_mode
	
	if Input.is_action_just_pressed("show_fps"):
		show_fps = not show_fps
		
	debug_label.visible = show_fps

func handle_fullscreen() -> void:
	if get_window().mode != Window.MODE_FULLSCREEN:
		get_window().mode = Window.MODE_FULLSCREEN
		_F.set_config_entry("fullscreen", true)
	else:
		get_window().mode = Window.MODE_WINDOWED
		_F.set_config_entry("fullscreen", false)

func _switch_render_mode() -> void:
	if Input.is_action_just_pressed("debug_render_mode"):
		if current_debug_draw < 4:
			current_debug_draw += 1
		else:
			current_debug_draw = 0
	
	get_viewport().debug_draw = current_debug_draw

func override_max_fps(override : bool = false, value : int = 0) -> void:
	if override:
		Engine.max_fps = value
		return
	
	Engine.max_fps = _F.get_config_entry("max_fps") 

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

func set_alert(text : String = "Something is happening", color : Color = Color.WHITE, speed : float = 0.4) -> void:
	_alert.text = text
	_alert.color = color
	_alert.speed = speed
	_alert.use_alert()

func clear_alerts() -> void:
	_alert.hide()
