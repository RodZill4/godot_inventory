# godot_inventory
An inventory component for the Godot Engine

## The demo
The (very simple) demo constists of:
* 4 "item generators" (yes, the 4 "GoBot" icons): drag from them and they'll generate an item.
* 4 inventory windows. You can grab their title to move them around, and move items around from and to those windows. They also have a context menu that can be used to "compact" the inventory. Inventory slots also have a context menu with "split" and "destroy" options.

## The inventory component
This component relies on 3 main classes/scenes:
* the item database, that describes the available items and provides methods to interact with items. This demo includes a minimal database. For each item, the database contains a name, an index (used to select the corresponding icon in the icons image)...
* an ObjectStack class that describes an object stack (item index + item count). It inherits from Control because it is used as preview when dragging items.
* an inventory class that inherits from PopupPanel and provides simple inventory features. It is necessary for the associated panel to contain a Label as first child (this will be the title of the window).

## Writing components that can drag'n'drop from/to the inventory
* The data that is dragged/dropped is an array that contains:
:* the source widget
:* the ObjectStack to be moved around
* To be able to receive items from the inventory, the following methods must be implemented:
:* can_drop_data(p, v): v is described above, this function returns true if v[1] can be dropped into self
:* drop_data(p, v): this function actually drops v into self, and if the drop operation is successful, notifies v[0] using v[0].stop_monitoring_drag()
* to be able to send items to the inventory, the following methods must be implemented:
:* get_drag_data(p): return the drag/drop data (basically [self, object_stack]).
:* stop_monitoring_drag(): this method is called if the drag'n'drop operation is successful.

## Todo
* Write documentation
* Fix the ugly monitoring hack. I implemented this because I didn't manage to detect when the object is dropped into an unexpected place, so the inventory class keeps track of the drag'n'drop opeartion until the mouse button is released.
