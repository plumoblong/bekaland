extends Resource
class_name InventorySlot

@export var item : Item
@export var quantity : int = 0

signal on_refresh

func is_empty() -> bool:
	return item == null or quantity <= 0

func can_add(amount: int) -> int:
	# returns how much fits before hitting max_stack
	if item == null:
		return 0
	return min(amount, item.max_stack - quantity)

func get_string() -> String:
	var si : String = ""
	var sq : String = ""
	if item:
		si = item.name
	if quantity != 0:
		sq = " x" + str(quantity)
	return si + sq

func add(slot: InventorySlot, count: int = -1) -> int:
	if slot == null or slot == self:
		return 0

	if slot.is_empty():
		return 0

	if count == 0:
		return 0

	# how much the source is willing to give
	var available: int = slot.quantity if count < 0 else mini(count, slot.quantity)
	if available <= 0:
		return 0

	var moved: int = 0

	if is_empty():
		item = slot.item
		quantity = mini(available, slot.item.max_stack)
		moved = quantity
	else:
		if item != slot.item:
			return 0

		var space: int = item.max_stack - quantity
		if space <= 0:
			return 0

		moved = mini(space, available)
		quantity += moved

	slot.quantity -= moved
	
	if slot.quantity <= 0:
		slot.set_empty()

	slot.on_refresh.emit()
	on_refresh.emit()
	return moved

func is_full() -> bool:
	if item == null:
		return false
	return quantity >= item.max_stack

func place_item(pos : Vector3, rotation : Vector3) -> void:
	if is_empty(): return
	if item.placeable_id == Game.Placeables.NONE: return

	var p : Placeable = _G.game.get_placeable(item.placeable_id)
	_G.game.player_obj.add_child(p, true)
	
	p.global_position = pos
	p.global_rotation = rotation
	quantity -= 1
	if is_empty():
		set_empty()
	
	on_refresh.emit()

func set_empty() -> void:
	quantity = 0
	item = null
	on_refresh.emit()
