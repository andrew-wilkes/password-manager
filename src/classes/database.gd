extends Reference

class_name Database

# Array of dictionaries (records)
var items = []

class ItemSorter:
	var key
	var reverse
	
	func sort(a, b):
		if reverse:
			return b[key] < a[key]
		else:
			return a[key] < b[key]


func order_items(key, reverse):
	var sorter = ItemSorter.new()
	sorter.key = key
	sorter.reverse = reverse
	items.sort_custom(sorter, "sort")
