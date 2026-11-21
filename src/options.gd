extends Control
class_name OptionsMenu

@onready var fullscreen: CheckButton = $Container/VBoxContainer/Fullscreen
@onready var shadows: CheckButton = $Container/VBoxContainer/Shadows
@onready var hide_screenshot: CheckButton = $Container/VBoxContainer/HideScreenshot
@onready var render_dist_text: Label = $Container/VBoxContainer/RenderDistText
@onready var render_dist: HSlider = $Container/VBoxContainer/RenderDist
@onready var header_input: Label = $Container/VBoxContainer/HeaderInput
@onready var mouse_sens_text: Label = $Container/VBoxContainer/MouseSensText
@onready var mouse_sens: HSlider = $Container/VBoxContainer/MouseSens
@onready var inv_scroll: CheckButton = $Container/VBoxContainer/InvScroll

signal back_pressed

const _CONFIG_ENTRY_LUT : Array[_F.ConfigEntry] = [
	_F.ConfigEntry.RENDER_DISTANCE_LOW,
	_F.ConfigEntry.RENDER_DISTANCE_NORMAL,
	_F.ConfigEntry.RENDER_DISTANCE_FAR,
]

const _CONFIG_ENTRY_TEXT_LUT : Array[String] = [
	"Low", "Normal", "Far"
]

func _process(_delta : float) -> void:
	update()

func update() -> void:
	fullscreen.button_pressed = _F.get_config_entry("fullscreen") as bool
	shadows.button_pressed = _F.get_config_entry("shadows") as bool
	hide_screenshot.button_pressed = _F.get_config_entry("hide_ui_when_screenshot") as bool
	inv_scroll.button_pressed = _F.get_config_entry("input_inv_scroll") as bool
	
	mouse_sens.value = _F.get_config_entry("input_mouse_vel") as float
	var rd : _F.ConfigEntry = _F.get_config_entry("render_distance") as _F.ConfigEntry
	
	match rd:
		_F.ConfigEntry.RENDER_DISTANCE_LOW:
			render_dist.value = 0.0
		_F.ConfigEntry.RENDER_DISTANCE_NORMAL:
			render_dist.value = 1.0
		_F.ConfigEntry.RENDER_DISTANCE_FAR:
			render_dist.value = 2.0
	
	mouse_sens_text.text = "Mouse Velocity: " + str(mouse_sens.value)
	render_dist_text.text = "Render Distance: " + _CONFIG_ENTRY_TEXT_LUT[int(render_dist.value)]
	
func _on_fullscreen_pressed() -> void:
	_G.handle_fullscreen()
	
func _on_hide_screenshot_toggled(toggled_on: bool) -> void:
	_F.set_config_entry("hide_ui_when_screenshot", toggled_on)

func _on_render_dist_value_changed(value: float) -> void:
	_F.set_config_entry("render_distance", _CONFIG_ENTRY_LUT[int(value)])

func _on_mouse_sens_value_changed(value: float) -> void:
	_F.set_config_entry("input_mouse_vel", value)

func _on_inv_scroll_toggled(toggled_on: bool) -> void:
	_F.set_config_entry("input_inv_scroll", toggled_on)

func _on_back_pressed() -> void:
	back_pressed.emit()

func _on_shadows_toggled(toggled_on: bool) -> void:
	_F.set_config_entry("shadows", toggled_on)
