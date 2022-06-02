extends Reference

class_name Database

# Array of dictionaries (records)
var items = []

class ItemSorter:
	var key
	var reverse
	
	func sort(a, b):
		if reverse:
			return b["data"][key] < a["data"][key]
		else:
			return a["data"][key] < b["data"][key]


func order_items(key, reverse):
	var sorter = ItemSorter.new()
	sorter.key = key
	sorter.reverse = reverse
	items.sort_custom(sorter, "sort")
