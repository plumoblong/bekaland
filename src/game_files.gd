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

# ---------- WORLD SAVES ----------
const SAVE_ROOT : String = "user://saves/"
var current_slot : String = "world1"

func get_world_dir() -> String:
	return SAVE_ROOT + current_slot + "/"

## Every dimension gets its own folder so terrain never mixes
func get_dimension_dir(dimension_key : String) -> String:
	return get_world_dir() + dimension_key + "/"

func has_save() -> bool:
	return FileAccess.file_exists(get_world_dir() + "world.json")

func save_world(data : Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(get_world_dir())
	var f : FileAccess = FileAccess.open(get_world_dir() + "world.json", FileAccess.WRITE)
	if f == null:
		push_error("Could not write world.json")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_world() -> Dictionary:
	if not has_save():
		return {}
	var text : String = FileAccess.get_file_as_string(get_world_dir() + "world.json")
	var parsed : Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

## Terrain3D stores its regions as .res files
func has_terrain(dir : String) -> bool:
	if not DirAccess.dir_exists_absolute(dir):
		return false
	for file : String in DirAccess.get_files_at(dir):
		if file.ends_with(".res"):
			return true
	return false

## Trees/foliage + player placed objects, one file per dimension.
## store_var keeps Vector3 etc. exactly, and is compact for thousands of entries.
func save_objects(dir : String, data : Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var f : FileAccess = FileAccess.open(dir + "objects.sav", FileAccess.WRITE)
	if f == null:
		push_error("Could not write objects.sav")
		return
	f.store_var(data)
	f.close()

func load_objects(dir : String) -> Dictionary:
	var path : String = dir + "objects.sav"
	if not FileAccess.file_exists(path):
		return {}
	var f : FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data : Variant = f.get_var()
	f.close()
	return data if data is Dictionary else {}

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
