extends ColorRect
class_name CraftingSlotUI

@export var item_icon : TextureRect
@export var item_name_label : Label
@export var ingredients : HBoxContainer
@export var _station_icon : Sprite2D

var _recipe : CraftingRecipe
var _inventory : Inventory
var _stations : Array[CraftingRecipe.Station]

var _color : Color
var _color2 : Color

var _hovering : bool = false

signal selected(slot : CraftingSlotUI)

func _refresh() -> void:
	for i : int in mini(_recipe.inputs.size(), 5):
		var s : InventorySlotUI = ingredients.get_child(i)
		s.set_slot(_recipe.inputs[i])
		
	if _recipe.output.item:
		item_icon.texture = _recipe.output.item.icon
		item_name_label.text = _recipe.output.item.name
		
	match _recipe.required_station:
		CraftingRecipe.Station.WORKBENCH:
			_station_icon.frame_coords.x = 0
			_station_icon.show()
		CraftingRecipe.Station.ANVIL:
			_station_icon.frame_coords.x = 1
			_station_icon.show()
		CraftingRecipe.Station.FURNACE:
			_station_icon.frame_coords.x = 2
			_station_icon.show()
		_:
			_station_icon.hide()
	
func set_recipe(recipe : CraftingRecipe, inv : Inventory, stations : Array[CraftingRecipe.Station]) -> void:
	_inventory = inv
	_stations = stations
	_recipe = recipe
	_refresh()

func get_recipe() -> CraftingRecipe:
	return _recipe

func _process(delta: float) -> void:
	
	_color = _G.UI_BG_SELECTED_COLOR if _hovering else _G.UI_BG_NORMAL_COLOR
	_color2 = lerp(_color2, _color, delta * _G.UI_BG_TRANSITION_SPEED)
	color = Color.from_hsv(0.0, 0.0, _color2.v, 0.5)
	
	if _hovering:
		if Input.is_action_just_pressed("attack"):
			selected.emit(self)
	
func _on_mouse_entered() -> void:
	_hovering = true

func _on_mouse_exited() -> void:
	_hovering = false
