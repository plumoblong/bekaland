extends Control
class_name UI

var _p : Player

@onready var alive : Control = get_node("Alive")
@onready var death : Control = get_node("Death")
@onready var respawn_label : Label = get_node("Death/Respawn")

@onready var water_overlay : TextureRect = get_node("WaterOverlay")
@onready var time_label : Label = get_node("Alive/Time")

@onready var crosshair : TextureRect = get_node("Alive/Crosshair")
@onready var last_health_bar : ColorRect = get_node("Alive/Crosshair/LastHealth")

@onready var _health_tooltip_rect : ColorRect = get_node("Alive/Bars/HealthTooltip")

var _last_health_alpha : float = 0.0
var _c_alpha : float
var _c_alpha2 : float

const _HEART_AMOUNT : float = 6.0
var ui_visible : bool = true

@onready var health_bar : TextureRect = get_node("Alive/Bars/Health")
@onready var health_bar_bg : TextureRect = get_node("Alive/Bars/Health/Empty")

@onready var pulse_rect : ColorRect = get_node("Pulse")
var _pulse_tween : Tween

@onready var debug_label : Label = get_node("Debug")

var _health_tooltip : bool = false

func _ready() -> void:
	assert(get_parent() is Player)
	_p = get_parent()
	
	_health_tooltip_rect.mouse_entered.connect(_enable_health_tooltip)
	_health_tooltip_rect.mouse_exited.connect(_disable_health_tooltip)

func set_mouse(captured : bool = false) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else _C.uncaptured_mouse_mode
	_p.can_control = captured

func _process(delta : float) -> void:
	if not _p or not _G.game: return
	
	if _p.health.alive:
		_update_alive(delta)
		alive.show()
		death.hide()
		alive.visible = not _F.is_screenshoting and ui_visible and _p.health.alive
	else:
		_update_dead()
		alive.hide()
		death.show()

	_update_debug()
	
func _update_alive(delta : float) -> void:
	_update_clock()
	_update_bars()
	_update_water()
	_update_last_health(delta)
	_handle_tooltip()
	if Input.is_action_just_pressed("hide_ui"):
		ui_visible = not ui_visible
	#_update_crosshair(delta)

func _handle_tooltip() -> void:
	if _health_tooltip:
		_C.set_tooltip(str(int(_p.health.value * 100)) + "HP")

func _update_dead() -> void:
	respawn_label.text = "Respawning in " + str(ceili(_p.timer_respawn.time_left)) + " seconds."
	
func _update_water() -> void:
	water_overlay.visible = _p.oxygen < 1.0 or _p.is_in_water
	var c : float = (float(_p.is_submerged()) * 0.2) + (1.0 - _p.oxygen) * 0.55
	
	water_overlay.modulate.a = c
	
func _update_bars() -> void:
	health_bar.size.x = 14.0 * (_p.health.get_ratio() * _HEART_AMOUNT)
	health_bar_bg.size.x = 14.0 * _HEART_AMOUNT * _p.health.max_health

	
func _update_last_health(delta : float) -> void:
	if _last_health_alpha > 0.0:
		_last_health_alpha -= delta
		last_health_bar.visible = true
	else:
		last_health_bar.visible = false

func set_last_health(health : float = 1.0) -> void:
	last_health_bar.anchor_left = 0.45
	last_health_bar.anchor_right = 0.45 + (health * 0.1)
	_last_health_alpha = 1.0

func _update_crosshair(delta : float) -> void:
	_c_alpha = float(_p.ray.is_colliding())
	_c_alpha2 = lerpf(_c_alpha2, _c_alpha, delta * 6.0)
	crosshair.modulate.a = 0.25 + (snappedf(_c_alpha2, 0.2) * 0.5)
	
func _update_debug() -> void:
	if not OS.has_feature("debug"): return
	debug_label.visible = _G.debug_mode
	if _G.debug_mode:
		debug_label.text = "pos " + str(_p.global_position) + "\nray " + str(_G.game.ray.global_position) + "\n\noxygen " + str(_p.oxygen) + "\nsuffocation " + str(_p.timer_suffocation.time_left) + "\nanimals " + str(_G.game.spawner.animals_node.get_child_count()) + "\n\ntime " + str(_G.game.world_time) + "\nmoon phase " + str(_G.game.skybox.moon_phase) + "\n\nhealth " + str(_p.health.value) + "\ncan heal " + str(_p.health.can_natural_heal) + "\nfloor normal " + str(_p.movement.get_surface_normal()) + "\nvelocity " + str(_p.velocity) +  "\n\nfoliage count " + str(_G.game.generation.foliage_count)

func _update_clock() -> void:
	var t : float = fposmod(_G.game.world_time + 0.25, 1.0)
	var total_minutes : int = roundi(t * 1440.0)
	
	var hours : int  = total_minutes / 60
	var minutes : int  = total_minutes % 60
	
	time_label.text = "%02d:%02d" % [hours, minutes]
	
	pulse_rect.color.a = snappedf(pulse_rect.color.a, 0.25)

func pulse(color : Color = Color(1.0, 0.32, 0.32, 0.71), time : float = 0.3) -> void:
	var end_color : Color = color * Color(1.0, 1.0, 1.0, 0.0)
	
	if _pulse_tween:
		_pulse_tween.kill()
	
	pulse_rect.color = color
	
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(pulse_rect, "color", end_color, time).set_trans(Tween.TRANS_LINEAR)

func _disable_health_tooltip() -> void:
	print("no")
	_health_tooltip = false
	_C.set_tooltip("")
	
func _enable_health_tooltip() -> void:
	print("yes")
	_health_tooltip = true
