extends Node
class_name GameFiles

enum ConfigEntry {
	RENDER_DISTANCE_LOW = 150,
	RENDER_DISTANCE_NORMAL = 300,
	RENDER_DISTANCE_FAR = 600,
}

@export var config : Dictionary[StringName, Variant] = {
	"input_mouse_vel" = 0.5,
	"input_inv_scroll" = false,
	"fullscreen" = false,
	"render_distance" = ConfigEntry.RENDER_DISTANCE_NORMAL,
	"hide_ui_when_screenshot" = false,
}

var CONFIG_PATH : String = "user://config.json" 
var SCREENSHOT_PATH : String = "user://screenshots/"

signal config_entry_changed(entry : StringName, value)

signal screenshot_start
signal screenshot_end

var is_screenshoting : bool = false
var screenshot_textures : Array[ImageTexture]

func setup() -> void:
	_load_screenshots()

func get_config_entry(entry : StringName) -> Variant:
	var e = config[entry] if config.has(entry) else null
	return e
	
func set_config_entry(entry : StringName, value) -> void:
	if not config.has(entry):
		print("Config entry ", entry, " is null. Returning")
		return
	config[entry] = value
	config_entry_changed.emit(entry, value)

func save_config() -> void:
	var c : FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	
	if c == null:
		return
	
	c.store_line(JSON.stringify(config))
	c.close()
	
func _load_screenshots() -> void:
	
	var dir = DirAccess.open("user://")
	
	dir.make_dir("screenshots") 
	
	dir = DirAccess.open(SCREENSHOT_PATH)
	
	var s : PackedStringArray = dir.get_files()
	
	if s.is_empty():
		return
	
	for n : String in dir.get_files():
		var t : ImageTexture = _assemble_texture(SCREENSHOT_PATH + n)
		screenshot_textures.append(t)

func _assemble_texture(path : String) -> ImageTexture:
	var i : Image = Image.load_from_file(path)
	if not i:
		return null
	var t : ImageTexture = ImageTexture.create_from_image(i)
	return t

func screenshot() -> void:
	is_screenshoting = true
	await get_tree().create_timer(0.05).timeout
	screenshot_start.emit()
	
	await RenderingServer.frame_post_draw
	
	var image : Image = get_viewport().get_texture().get_image()
	image.resize(640, 512, Image.INTERPOLATE_NEAREST)
	
	var date : Dictionary = Time.get_datetime_dict_from_system(false)
	var date_string : String = str(date.year) + "-" + str(date.month) + "-" + str(date.day) + " " + str(date.hour) + "" + str(date.minute) + "" + str(date.second)
	
	var image_path : String = SCREENSHOT_PATH + date_string + ".png"
	image.save_png(image_path)
	
	_G.set_alert("Screenshot saved as " + date_string + ".png")
	
	screenshot_end.emit()
	await get_tree().create_timer(0.05).timeout
	is_screenshoting = false
