extends Node
class_name GameFiles

enum ConfigEntry {
	RENDER_DISTANCE_LOW = 150,
	RENDER_DISTANCE_NORMAL = 300,
	RENDER_DISTANCE_FAR = 600,
}	

var _config : Dictionary[StringName, Variant] = {
	"input_mouse_vel" = 1.0,
	"input_inv_scroll" = true,
	"max_fps" = 0,
	"fullscreen" = false,
	"shadows" = true,
	"render_distance" = ConfigEntry.RENDER_DISTANCE_NORMAL,
	"hide_ui_when_screenshot" = true,
}

var CONFIG_PATH : String = "user://config.json" 
var SCREENSHOT_PATH : String = "user://screenshots/"

signal config_entry_changed(entry : StringName, value)

signal screenshot_start
signal screenshot_end

var is_screenshoting : bool = false
var screenshot_textures : Array[ImageTexture]

# ---------- WORLD SAVE (single world) ----------
const SAVE_ROOT : String = "user://saves/"
const WORLD_DIR : String = SAVE_ROOT + "world/"

func get_world_dir() -> String:
	return WORLD_DIR

## Every dimension gets its own folder so terrain never mixes
func get_dimension_dir(dimension_key : String) -> String:
	return WORLD_DIR + dimension_key + "/"

## True when a save file exists (the "Continue" button uses this)
func has_save() -> bool:
	return FileAccess.file_exists(WORLD_DIR + "world.json")

## Same as has_save() but also makes sure the file is readable
func can_continue() -> bool:
	return not load_world().is_empty()

## "New Game": wipes the old world (if any) and starts from an empty folder.
## Call it, then change to the game scene: with no world.json there,
## Game generates a fresh world with a new seed.
## (Ask the player to confirm first if has_save() is true!)
func new_game() -> void:
	_delete_dir_recursive(WORLD_DIR)
	DirAccess.make_dir_recursive_absolute(WORLD_DIR)

func save_world(data : Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(WORLD_DIR)
	var f : FileAccess = FileAccess.open(WORLD_DIR + "world.json", FileAccess.WRITE)
	if f == null:
		push_error("Could not write world.json")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func load_world() -> Dictionary:
	if not has_save():
		return {}
	var text : String = FileAccess.get_file_as_string(WORLD_DIR + "world.json")
	var parsed : Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

func _delete_dir_recursive(path : String) -> void:
	var dir_path : String = path.trim_suffix("/") + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for file : String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path + file)
	for sub_dir : String in DirAccess.get_directories_at(dir_path):
		_delete_dir_recursive(dir_path + sub_dir)
	DirAccess.remove_absolute(dir_path.trim_suffix("/"))

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
	var e = _config[entry] if _config.has(entry) else null
	return e
	
func set_config_entry(entry : StringName, value) -> void:
	if not _config.has(entry):
		print("Config entry ", entry, " is null. Returning")
		return
	_config[entry] = value
	config_entry_changed.emit(entry, value)

func update_config_entries() -> void:
	for i : StringName in _config.keys():
		config_entry_changed.emit(i, _config[i])

func save_config() -> void:
	var c : FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	
	if c == null:
		return
	
	c.store_line(JSON.stringify(_config))
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
