extends CanvasLayer
class_name GameCursor

enum Frame {
	ARROW = 0,
	POINTER = 1,
	WAIT = 2,
	DENY = 3,
}

const _OFFSETS : PackedVector2Array = [
	Vector2(0.0, 0.0), Vector2(-5.0, -1.0), Vector2.ZERO, Vector2.ZERO
]

@onready var _sprite : Sprite2D = $Cursor
@onready var _tooltip : Label = $Cursor/Tooltip

@onready var slot_ui : InventorySlotUI = $Cursor/Slot
@export var slot : InventorySlot

var uncaptured_mouse_mode : Input.MouseMode = Input.MOUSE_MODE_HIDDEN

var _tooltip_alpha : float = 0.0
var _t_alpha2 : float = 0.0

func _ready() -> void:
	Input.mouse_mode = uncaptured_mouse_mode
	set_frame(Frame.ARROW)
	slot_ui.set_slot(slot)
	set_tooltip("")

func _process(delta) -> void:
	_sprite.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	_sprite.position = Vector2i(get_viewport().get_mouse_position())
	_t_alpha2 = lerpf(_t_alpha2, _tooltip_alpha, delta * 8.0)
	_tooltip.modulate.a = snappedf(_t_alpha2, 0.25)
	visible = not _F.is_screenshoting

func set_frame(new : Frame = Frame.ARROW) -> void:
	_sprite.frame = new
	_sprite.offset = _OFFSETS[_sprite.frame]

func set_slot_item(item : Item) -> void:
	slot.item = item
	slot_ui._refresh() 

func add_slot_quantity(amount : int = 1) -> void:
	slot.quantity += amount
	if slot.is_empty():
		slot.set_empty()
		return
	slot_ui._refresh()

func set_tooltip(text : String = "") -> void:
	if text == "":
		_tooltip_alpha = 0.0
		return
	_tooltip.text = text
	_tooltip_alpha = 1.0
