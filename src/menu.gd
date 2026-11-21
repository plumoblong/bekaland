extends Control

@onready var main_screen : Control = get_node("Main")
@onready var options_screen : Control = get_node("Options")
var screen : int = 0

## Assign your "Continue" button in the inspector
@export var continue_button : Button

var GAME_SCENE : PackedScene = preload("res://scene/game.tscn")

@onready var popup : PopupScreen = get_node("Main/Popup")
var _starting : bool = false

func _ready() -> void:
	_refresh_continue_button()

func _process(_delta: float) -> void:
	main_screen.visible = screen == 0
	options_screen.visible = screen == 1

## Disabled first, enabled only if there is a save we can actually load
func _refresh_continue_button() -> void:
	if continue_button == null:
		return
	continue_button.disabled = true
	
	print(_F.can_continue())
	
	if _F.can_continue():
		continue_button.disabled = false

func _on_new_game_pressed() -> void:
	if _starting:
		return
	if _F.has_save():
		popup.activate(0, true, "Starting a new game will delete your current save.\nAre you sure?", "Delete & Start", "Cancel")
	else:
		_start_game(true)

# the old signal name, so an existing Start button connection keeps working
func _on_start_pressed() -> void:
	_on_new_game_pressed()

func _on_continue_pressed() -> void:
	if _starting or not _F.can_continue():
		return
	_start_game(false)

func _start_game(new_game : bool) -> void:
	if _starting:
		return
	_starting = true
	
	_G.is_starting_new_game = new_game
	if new_game:
		_F.new_game() # wipes the old world, Game will generate a fresh one
	_G.override_max_fps(true, 10)
	_G.loading_screen.activate("Generating..." if new_game else "Loading...")
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_packed(GAME_SCENE)

func _on_quit_pressed() -> void:
	popup.activate(1, false, "Quit to OS?", "Yes.", "Keep playing")

func _on_popup_accepted() -> void:
	if popup.current_id == 0:
		_start_game(true)
	elif popup.current_id == 1:
		get_tree().quit()

func _on_options_pressed() -> void:
	screen = 1

func _on_options_back_pressed() -> void:
	screen = 0
