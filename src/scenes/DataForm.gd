extends MarginContainer

signal action(id, data)

enum { LIGHT, DARK, HIGHLIGHTED }

export(Color) var light_color
export(Color) var dark_color
export(Color) var highlight_color

var heading_scene = preload("res://scenes/Heading.tscn")
var cell_scene = preload("res://scenes/Cell.tscn")
var group_button = preload("res://scenes/GroupButton.tscn")
var view_button = preload("res://scenes/ViewButton.tscn")
onready var header = find_node("Header")
onready var grid: GridContainer = $VB/SC/Grid
var headings = {
	"title": "Title",
	"username": "Username",
	"url": "URL",
	"accessed": "Accessed",
}
var settings: Settings
var database: Database
var update_bars = false
var current_group = 0
var current_key = ""
var current_reverse_state = false
var searchtext = ""
var num_rows = 0

func _ready():
	emit_signal("action", null)
	for key in headings:
		var heading = heading_scene.instance()
		heading.set_sort_mode(heading.NONE)
		heading.find_node("Label").text = headings[key]
		heading.db_key = key
		heading.connect("clicked", self, "heading_clicked")
		header.add_child(heading)


func populate_grid(db: Database, key, reverse, group, filter = ""):
	num_rows = 0
	current_key = key
	current_reverse_state = reverse
	if not key.empty():
		db.order_items(key, reverse)
	for idx in grid.get_child_count():
		grid.get_child(idx).queue_free()
	for item in db.items:
		if group > 0 and not group in item.groups:
			continue
		if not filter.empty():
			if not filter.is_subsequence_ofi(item.title + item.username + item.url):
				continue
		num_rows += 1
		var vb = view_button.instance()
		var _e = vb.connect("view_button_pressed", self, "show_item_details", [item])
		grid.add_child(vb)
		for key in headings:
			var cell = cell_scene.instance()
			var font_color = Color.black
			if item.expire < 0 and key == "title":
				font_color = Color.red
			cell.set_text(get_cell_content(item, key), key == "url", font_color)
			grid.add_child(cell)


func remove_group(group_id):
	for item in database.items:
		item.groups.erase(group_id)
	if current_group == group_id:
		current_group = 0
		populate_grid(database, "", false, 0)
	update_group_buttons()


func show_item_details(item):
	$ItemDetails.open(item, settings)


func add_bars():
	var num_bars_existing = $BG/SC/VBox.get_child_count()
	if num_bars_existing == 0:
		var bar = ColorRect.new()
		bar.color = light_color
		#bar.rect_min_size = Vector2(grid.rect_size.x, row_height)
		$BG/SC/VBox.add_child(bar)
		num_bars_existing = 1
	var to_add = num_rows - num_bars_existing
	if to_add > 0:
		var bar = $BG/SC/VBox.get_child(0)
		var color_idx = num_bars_existing
		for n in to_add:
			bar = bar.duplicate()
			bar.color = [light_color, dark_color][color_idx % 2]
			color_idx += 1
			$BG/SC/VBox.add_child(bar)
	if to_add < 0:
		for idx in range(num_bars_existing + to_add, num_bars_existing):
			$BG/SC/VBox.get_child(idx).queue_free()
	var idx = 0
	for bar in $BG/SC/VBox.get_children():
		bar.rect_min_size.y = grid.get_child(idx).rect_size.y
		idx += 5


func get_cell_content(data, key):
	var txt = ""
	match key:
		"accessed":
			var date = OS.get_datetime_from_unix_time(data[key])
			txt = Date.format(date, settings.date_format)
		"notes":
			var idx = data[key].find("\n")
			if idx > -1:
				txt = data[key].left(idx)
		_: txt = data[key]
	return txt


func add_dummy_data():
	var r1 = Record.new()
	r1.data.title = "Title of entry"
	r1.data.username = "User1"
	r1.data.url = "https://bing.com"
	r1.data.notes = "Just some notes\nNext line"
	r1.data.modified = OS.get_unix_time()
	database.items.append(r1.data)
	for n in 8:
		var r = Record.new()
		r.data = r1.data.duplicate()
		r.data.title = char(97 + randi() % 8).repeat(6)
		r.data.username = char(65 + n).repeat(randi() % 8 + 2)
		r.data.modified = OS.get_unix_time_from_datetime(OS.get_datetime_from_unix_time(randi()))
		r.data.notes = str(randi()).md5_text()
		database.items.append(r.data)


func init(data):
	visible = true
	settings = data.settings
	database = data.database
	#add_dummy_data()
	populate_grid(database, "", false, 0)
	update_group_buttons()
	$VB/SB/SearchBox.grab_focus()
	check_for_reminders()


func check_for_reminders():
	var now = OS.get_unix_time()
	for item in database.items:
		if item.expire > 0 and item.expire < now:
			item.expire = -1
		if item.remind > 0 and item.remind < now:
			item.remind = -1
			show_item_details(item)
			break


func update_group_buttons():
	var existing_buttons = []
	for node in $VB/Groups/Grid.get_children():
		node.pressed = true if node.id == 0 else false
		if node.id == 0 or node.id in settings.groups:
			existing_buttons.append(node.id)
		else:
			node.queue_free()
	for group_id in settings.groups:
		if group_id in existing_buttons:
			continue
		var gb = group_button.instance()
		gb.id = group_id
		gb.text = settings.groups[group_id]
		var _e = gb.connect("group_button_pressed", self, "set_group")
		$VB/Groups/Grid.add_child(gb)


func set_group(id):
	current_group = id
	populate_grid(database, current_key, current_reverse_state, current_group)


func heading_clicked(heading: Heading):
	var idx = 1
	for key in headings:
		if key != heading.db_key:
			grid.get_child(idx).set_sort_mode(heading.NONE)
		idx += 1
	populate_grid(database, heading.db_key, bool(heading.sort_mode), current_group)


func _on_Grid_item_rect_changed():
	#$BG/SC.rect_position = grid.rect_global_position
	#update_bars = true
	pass

func _process(_delta):
	if update_bars:
		add_bars()
		update_bars = false


func _on_DataForm_visibility_changed():
	$BG/MC.visible = visible


func _on_ItemDetails_delete_item(item):
	database.items.erase(item)
	populate_grid(database, "", false, 0)


func _on_Add_pressed():
	var record = Record.new()
	var item = record.data
	item.created = OS.get_unix_time()
	database.items.push_front(item)
	show_item_details(item)


func _on_ItemDetails_popup_hide():
	populate_grid(database, current_key, current_reverse_state, current_group)
	check_for_reminders()


func _on_SearchBox_text_changed(new_text):
	searchtext = new_text
	$SearchTimer.start()


func _on_SearchTimer_timeout():
	populate_grid(database, "", false, 0, searchtext)


func csv_import(path, csv_data):
	$CSVImport.open(path, csv_data, database, settings)


func _on_CSVImport_update_groups():
	update_group_buttons()


func _on_CSVImport_update_item_list():
	populate_grid(database, current_key, current_reverse_state, current_group)


func keepass_import(path, keepass_data):
	$KeePassImport.open(path, keepass_data, database, settings)


func _on_KeePassImport_update_item_list():
	populate_grid(database, current_key, current_reverse_state, current_group)


func _on_KeePassImport_update_groups():
	update_group_buttons()
