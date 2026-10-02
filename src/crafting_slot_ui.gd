extends ColorRect
class_name CraftingSlotUI

@export var item_icon: TextureRect
@export var count_label: Label
@export var debug_label: Label

@export var recipe : CraftingRecipe

var _slot : InventorySlot

func _refresh() -> void:
	if _slot == null or _slot.is_empty():
		item_icon.texture = null
		item_icon.visible = false
		count_label.visible = false
		return
	
	item_icon.visible = true
	item_icon.texture = _slot.item.icon
	count_label.visible = _slot.quantity > 1
	count_label.text = str(_slot.quantity)
