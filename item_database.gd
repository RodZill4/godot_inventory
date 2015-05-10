extends Node

const ITEM_NAME         = 0
const ITEM_STACKS       = 1
const ITEM_ICON         = 2
const ITEM_SPRITE       = 3
const ITEM_TYPE         = 4

const ITEM_CANNOT_USE = 0
const ITEM_USED       = 1
const ITEM_CONSUMED   = 2

var item_database = [
	{
		ITEM_NAME : "Blue GoBot",
		ITEM_STACKS : true,
		ITEM_ICON : 0,
		ITEM_SPRITE : 0
	},
	{
		ITEM_NAME : "Red GoBot",
		ITEM_STACKS : true,
		ITEM_ICON : 1,
		ITEM_SPRITE : 1
	},
	{
		ITEM_NAME : "Yellow GoBot",
		ITEM_STACKS : true,
		ITEM_ICON : 2,
		ITEM_SPRITE : 2
	},
	{
		ITEM_NAME : "Green GoBot",
		ITEM_STACKS : true,
		ITEM_ICON : 3,
		ITEM_SPRITE : 3
	}
]

var item_map = { }

func _ready():
	for i in range(item_database.size()):
		item_map[item_database[i][ITEM_NAME]] = i

func get_item(n):
	return item_map[n]

func get_item_name(i):
	return item_database[i][ITEM_NAME]

func get_item_stacks(i):
	return item_database[i][ITEM_STACKS]

func get_item_icon(i):
	return item_database[i][ITEM_ICON]

func get_item_sprite(i):
	return item_database[i][ITEM_SPRITE]

func can_use_item(i):
	return use_item(i, true) != ITEM_CANNOT_USE

func use_item(i, pretend = false):
	var item = item_database[i]
	if item.has(ITEM_TYPE):
		print("Test item type here...")
	return ITEM_CANNOT_USE



