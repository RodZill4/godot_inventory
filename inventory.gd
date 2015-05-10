extends PopupPanel

export(String) var name      = "Inventory"
export(int)    var size      = 5
export(int)    var top_space = 0
export(bool)   var collapsed = false

var slots = []

var moving = false
var old_mouse_pos
var menu
var ItemDatabase

const ObjectStack  = preload("res://object_stack.gd")

const CAN_DRAG_WINDOW = true

const SLOT_SIZE = 32

const MENU_USE      = 0
const MENU_SPLIT    = 1
const MENU_DESTROY  = 2
const MENU_COMPRESS = 3

# A class for an inventory slot
# Handles drag, drop, menu (use, split, destroy)
class Slot:
	extends Control
	var container = null
	var stack     = null
	var menu      = null
	var dragging  = null
	var timer     = null
	var ItemDatabase
	
	func _init(c):
		container = c
	
	func _ready():
		ItemDatabase = get_node("/root/item_database")
		set_size(Vector2(SLOT_SIZE + 2, SLOT_SIZE + 2))
	
	func _draw():
		draw_rect(Rect2(Vector2(0, 0), get_size()), Color(0.2, 0.2, 0.2, 1))
	
	func _input_event(event):
		if event.type == InputEvent.MOUSE_BUTTON:
			if event.button_index == 2:
				print(get_pos())
				show_menu(get_global_transform().get_origin() + event.pos)
				accept_event()
			elif event.button_index == 1:
				if !event.pressed:
					show_menu(get_global_transform().get_origin() + event.pos)
					accept_event()
	
	func update_contents():
		container.on_Update_inventory_contents()
		if stack != null:
			set_tooltip(ItemDatabase.get_item_name(stack.item))
			stack.set_size(Vector2(SLOT_SIZE, SLOT_SIZE))
			stack.set_pos(Vector2(1, 1))
			stack.layout()
		else:
			set_tooltip("")
	
	func can_drop_data(p, v):
		return can_add_stack(v[1])
	
	func drop_data(p, v):
		if !add_stack(v[1]) && v[0].has_method("add_stack"):
			v[0].add_stack(remove())
			add_stack(v[1])
		v[0].stop_monitoring_drag()
	
	func get_drag_data(p):
		if stack == null:
			return null
		# drag data is an array containing
		# * the container (used to swap with the contents of the destination)
		# * the dragged stack 
		var object = [self, stack]
		remove_child(stack)
		# duplicate the stack for the preview (will be destroyed automatically)
		var drag_preview = ObjectStack.new(stack.item, stack.count)
		drag_preview.set_size(Vector2(SLOT_SIZE, SLOT_SIZE))
		set_drag_preview(drag_preview)
		# we have to monitor the drag operation, in case the drop operation
		# is not handled
		start_monitoring_drag(stack)
		stack = null
		update_contents()
		return object
	
	func start_monitoring_drag(o):
		if dragging != null:
			print("error, already dragging")
		dragging = o
		timer = Timer.new()
		add_child(timer)
		timer.connect("timeout", self, "monitor_drag")
		timer.set_wait_time(0.1)
		timer.start()
	
	func monitor_drag():
		# if mouse button is not pressed anymore, drag was not handled. Cancel it
		if dragging != null && !Input.is_mouse_button_pressed(1):
			stack = dragging
			add_child(stack)
			stack.set_size(Vector2(SLOT_SIZE, SLOT_SIZE))
			stack.set_pos(Vector2(1, 1))
			stack.layout()
			stop_monitoring_drag()
	
	func stop_monitoring_drag():
		if dragging == null:
			print("error, was not dragging")
		else:
			dragging = null
		if timer == null:
			print("error, lost timer")
		else:
			timer.stop()
			timer.queue_free()
			timer = null
	
	func can_add_stack(s):
		return stack == null || stack.can_stack(s)
	
	func add_stack(s):
		var rv
		if stack == null:
			stack = s
			add_child(stack)
			rv = true
		else:
			rv = stack.stack(s)
		update_contents()
		return rv
	
	func get():
		return stack
	
	func set(s):
		if stack == null:
			stack = s
			add_child(stack)
			update_contents()
			return true
		return false
	
	func get_count():
		if stack == null:
			return 0
		else:
			return stack.count
	
	func remove(c = null):
		var s
		if c == null || c >= stack.count:
			s = stack
			remove_child(stack)
			stack = null
		else:
			s = stack.split(c)
		update_contents()
		return s

	func merge(s):
		if stack == null:
			set(s.remove())
		elif stack.can_stack(s.get()):
			stack.stack(s.remove())
		update_contents()
	
	func show_menu(pos):
		if menu != null:
			menu.queue_free()
		if get_count() > 0:
			menu = PopupMenu.new()
			menu.connect("item_pressed", self, "_menu_item")
			# "Use" item (if contents is usable)
			if get_node("/root/item_database").can_use_item(stack.item):
				menu.add_item("Use", MENU_USE)
			# "Split" button (for stacks)
			if get_count() > 1:
				if container.has_empty_slots():
					menu.add_item("Split", MENU_SPLIT)
			menu.add_item("Destroy", MENU_DESTROY)
			if menu.get_item_count() > 0:
				add_child(menu)
				menu.set_pos(pos)
				menu.popup()
				return
		menu = null
	
	func _menu_item(id):
		var pos = menu.get_pos()
		menu.queue_free()
		menu = null
		if id == MENU_USE:
			var use_result = get_node("/root/item_database").use_item(stack.item)
			if use_result == ItemDatabase.ITEM_CONSUMED:
				if get_count() == 1:
					stack.queue_free()
					stack = null
				else:
					stack.split(1)
		elif id == MENU_SPLIT:
			if get_count() == 2:
				container.add_stack(stack.split(1), false)
			else:
				menu = PopupPanel.new()
				add_child(menu)
				var spinbox = SpinBox.new()
				menu.add_child(spinbox)
				spinbox.set_pos(Vector2(1, 1))
				spinbox.set_value(stack.count>>1)
				spinbox.set_min(1)
				spinbox.set_max(stack.count-1)
				spinbox.set_step(1)
				var button = Button.new()
				menu.add_child(button)
				button.set_text("OK")
				button.set_pos(Vector2(2+spinbox.get_size().x, 1))
				button.connect("pressed", self, "_split_ok")
				menu.set_pos(pos)
				menu.set_size(spinbox.get_size()+Vector2(3+button.get_size().x, 2))
				menu.popup()
		elif id == MENU_DESTROY:
			remove_child(stack)
			stack = null
			update_contents()
	
	func _split_ok():
		var count = int(menu.get_child(0).get_value())
		container.add_stack(stack.split(count), false)
		menu.queue_free()
		menu = null

func _ready():
	ItemDatabase = get_node("/root/item_database")
	if size < 1:
		queue_free()
		return
	# First child should be a label
	get_child(0).set_text(name)
	for i in range(size):
		var slot = Slot.new(self)
		slot.set_name("slot_"+str(i))
		add_child(slot)
		slots.append(slot)
		slot.set_pos(Vector2(6+(SLOT_SIZE + 5)*(i%5), 25+top_space+(SLOT_SIZE + 5)*(i/5)))
	var cols = 5
	if size < 5:
		cols = size
	var rows = (size-1)/5 + 1
	collapse(collapsed)

func collapse(c):
	collapsed = c
	for c in get_children():
		if !c.is_type("Control") || c.get_name() == "Label":
			continue
		if collapsed:
			c.hide()
		else:
			c.show()
	var cols = 5
	if size < 5:
		cols = size
	if !collapsed:
		var rows = (size-1)/5 + 1
		set_size(Vector2(9+(SLOT_SIZE + 5)*cols, 27+top_space+(SLOT_SIZE + 5)*rows))
	else:
		set_size(Vector2(9+(SLOT_SIZE + 5)*cols, 27))
		
func _input_event(event):
	# handle left mouse button on the panel to move it
	if event.type == InputEvent.MOUSE_BUTTON && event.button_index == 1 && event.pressed:
		if CAN_DRAG_WINDOW:
			moving = true
			get_parent().move_child(self, get_parent().get_child_count()-1)
			old_mouse_pos = event.pos
		else:
			collapse(!collapsed)
	elif moving && event.type == InputEvent.MOUSE_MOTION:
		if !Input.is_mouse_button_pressed(1):
			moving = false
		else:
			set_pos(get_pos()+event.pos-old_mouse_pos)
			old_mouse_pos = event.pos
	# right mouse button shows the menu
	elif !moving && event.type == InputEvent.MOUSE_BUTTON && event.button_index == 2:
		show_menu(get_global_transform().get_origin() + event.pos)
	else:
		return
	accept_event()

func can_drop_data(p, v):
	return has_empty_slots()

func drop_data(p, v):
	if !add_stack(v[1]):
		v[0].add_stack(v[1])
	v[0].stop_monitoring_drag()

func show_menu(pos):
	if menu != null:
		menu.queue_free()
	menu = PopupMenu.new()
	add_child(menu)
	menu.connect("item_pressed", self, "_menu_item")
	menu.add_item("Compact", MENU_COMPRESS)
	menu.set_pos(pos)
	menu.popup()

func _menu_item(id):
	menu.queue_free()
	menu = null
	if id == MENU_COMPRESS:
		for i in range(1, size):
			for j in range(i):
				if slots[i].stack == null:
					break
				slots[j].merge(slots[i])

func has_empty_slots():
	for i in range(size):
		if slots[i].stack == null:
			return true
	return false

# Add an item stack
func add_stack(s, merge = true):
	if merge:
		for slot in slots:
			if slot.stack != null && slot.add_stack(s):
				return true
	for slot in slots:
		if slot.stack == null:
			slot.add_stack(s)
			return true
	return false

# Add items (by name, count)
func add_items(n, c):
	var itemdesc = ItemDatabase.get_item(n)
	if itemdesc == null:
		return false
	return add_stack(ObjectStack.new(itemdesc, c))

# Remove items (by name, count)
func remove_items(n, c):
	if (count_items(n) < c):
		return false
	var itemdesc = ItemDatabase.get_item(n)
	for slot in slots:
		if slot.stack != null && slot.stack.item == itemdesc:
			if slot.stack.count > c:
				slot.remove(c)
				return
			else:
				c -= slot.stack.count
				slot.remove()

# Count items by name
func count_items(n):
	var itemdesc = ItemDatabase.get_item(n)
	if itemdesc == -1:
		return 0
	var count = 0
	for slot in slots:
		if slot.stack != null && slot.stack.item == itemdesc:
			count += slot.stack.count
	return count

# This method is called whenever the inventory contents changes. Overload if needed 
func on_Update_inventory_contents():
	pass

# Return the contents of the inventory in a dictionary (useful for saving state)
func get_state():
	var s = {}
	for slot in slots:
		if slot.stack != null:
			s[slot.get_name()] = { item = slot.stack.item, count = slot.stack.count }
	return s

# Fill the inventory from a dictionary (useful for loading state)
func set_state(s):
	for slot in slots:
		var name = slot.get_name()
		if s.has(name):
			var contents = s[name]
			slot.set(ObjectStack.new(contents.item, contents.count))
