extends TextureFrame

export(int)    var itemid = 0

const ObjectStack  = preload("res://object_stack.gd")

func _ready():
	# Initialization here
	pass

func get_drag_data(p):
	var stack = ObjectStack.new(itemid, 1)
	var object = [self, stack]
	remove_child(stack)
	var drag_preview = ObjectStack.new(stack.item, stack.count)
	drag_preview.set_size(Vector2(32, 32))
	set_drag_preview(drag_preview)
	return object

func stop_monitoring_drag():
	print("Item was dropped")
