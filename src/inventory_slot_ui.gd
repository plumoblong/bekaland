extends ColorRect
class_name InventorySlotUI

@export var item_icon: TextureRect
@export var count_label: Label
@export var debug_label: Label

@export var disable_input : bool = false
@export var hotbar_slot : bool = false

var selected : bool = false

@export var slot : InventorySlot
var slot_id : int = -1
var inventory_id : int = -1

const BG_NORMAL_COLOR : Color = Color(0.0, 0.0, 0.0, 0.502)
const BG_HOVER_COLOR : Color = Color(1.0, 1.0, 1.0, 0.502)
const BG_TRANSITION_SPEED : float = 16.0
const BG_COLOR_SPLIT : float = 0.33

var _color : Color
var _color2 : Color

func _ready() -> void:
	color = Color.TRANSPARENT
	if not disable_input:
		color = BG_NORMAL_COLOR
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	_refresh()

func set_slot(new_slot: InventorySlot) -> void:
	if slot != null:
		if slot.on_refresh.is_connected(_refresh):
			slot.on_refresh.disconnect(_refresh)
		
	slot = new_slot
	slot.on_refresh.connect(_refresh)
	_refresh()
	
func _process(delta: float) -> void:
	if not disable_input:
		
		_color = BG_HOVER_COLOR if selected else BG_NORMAL_COLOR
		_color2 = lerp(_color2, _color, delta * BG_TRANSITION_SPEED)
		color = Color.from_hsv(0.0, 0.0, _color2.v, 0.5)
		
	debug_label.visible = _G.debug_mode
	if slot.item != null:
		debug_label.text = str(slot_id) + "\n" + str(slot.item.name)
	else:
		debug_label.text = str(slot_id)

func _refresh() -> void:
	if slot == null or slot.is_empty():
		
		item_icon.texture = null
		item_icon.visible = false
		count_label.visible = false
		return
	
	item_icon.visible = true
	item_icon.texture = slot.item.icon
	count_label.visible = slot.quantity > 1
	count_label.text = str(slot.quantity)

func _gui_input(event: InputEvent) -> void:
	if disable_input: return
	if event is InputEventMouseButton and event.pressed:
		_handle_mouse_inventory(event.button_index)
					
					
func _handle_mouse_inventory(e : MouseButton) -> void:
	match e:
		MOUSE_BUTTON_WHEEL_DOWN:
			if slot.is_empty():
				return
			
			_C.slot.add(slot, 1)
			
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_RIGHT:
			slot.add(_C.slot, 1)
			
		MOUSE_BUTTON_LEFT:
			if slot.is_empty():
				if _C.slot.is_empty():
					return
				
				slot.add(_C.slot)
				_C.slot.set_empty()
				_on_mouse_entered()
				
			else:
				if _C.slot.is_full():
					return

				var s : int = _C.slot.add(slot)
				if s: slot.set_empty()
			
func _on_mouse_entered() -> void:
	selected = true
	if not slot.is_empty():
		_C.set_tooltip(slot.item.name)
	
func _on_mouse_exited() -> void:
	selected = false
	_C.set_tooltip("")
