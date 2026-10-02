extends CanvasLayer
class_name LoadingScreen

@export var textures : Array[Texture2D]

@onready var loading_texture : TextureRect = $Texture
@onready var header_text : Label = $Text
@onready var background_texture : TextureRect = $Background

func _ready() -> void:
	dectivate()

func _set_background() -> void:
	var t : Texture2D = null if _F.screenshot_textures.is_empty() else _F.screenshot_textures.pick_random()
	if t == null:
		background_texture.hide()
		return
	background_texture.texture = t

func activate(text : String = "Loading...", bg : bool = true) -> void:
	loading_texture.texture = textures.pick_random()
	#get_window().always_on_top = true
	header_text.text = text
	if bg:
		_set_background()
	else:
		background_texture.hide()
	show()

func dectivate() -> void:
	#get_window().always_on_top = false
	hide()
