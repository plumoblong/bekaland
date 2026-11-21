extends Control
class_name PopupScreen

@onready var confirm_button : Button = get_node("HBoxContainer/Confirm")
@onready var close_button : Button = get_node("HBoxContainer/Close")
@onready var label : Label = get_node("HBoxContainer/Label")
@onready var warning : Node2D = get_node("Warning")

signal accepted
signal closed

var shown : bool = false

var current_id : int = 0
var _warning_visible : bool = false
var _show_warning : bool = false

func _ready() -> void:
	confirm_button.pressed.connect(_confirm_button_pressed)
	close_button.pressed.connect(_close_button_pressed)

func activate(id : int, show_warning : bool = false,  info : String = "Error", accept_text : String = "Accept", close_text : String = "Close") -> void:
	shown = true
	label.text = info
	_show_warning = show_warning
	confirm_button.text = accept_text
	close_button.text = close_text
	current_id = id
	show()

func _physics_process(_delta: float) -> void:
	
	warning.visible = _warning_visible and _show_warning and shown
	if not shown: 
		return
	warning.scale = get_viewport_rect().size / _G.VIEWPORT_SCALE
	
	if Engine.get_physics_frames() % 24 == 0:
		_warning_visible = not _warning_visible
	
func _confirm_button_pressed() -> void:
	accepted.emit()
	shown = false
	hide()
	
func _close_button_pressed() -> void:
	closed.emit()
	shown = false
	hide()
