extends VBoxContainer

signal action(id, data)

enum { LIGHT, DARK, HIGHLIGHTED }

export(Color) var light_color
export(Color) var dark_color
export(Color) var highlight_color

var heading_scene = preload("res://scenes/Heading.tscn")
var cell_scene = preload("res://scenes/Cell.tscn")
var group_button = preload("res://scenes/GroupButton.tscn")
var grid: GridContainer
var headings = {
	"title": "Title",
	"username": "Username",
	"url": "URL",
	"notes": "Notes",
	"modified": "Modified",
}
var settings: Settings
var database: Database
var heading_height = 0
var row_height = 0
var update_bars = false
var current_group = 0
var current_key = ""
var current_reverse_state = false

func populate_grid(db: Database, key, reverse, group):
	if not key.empty():
		db.order_items(key, reverse)
	for idx in range(grid.columns, grid.get_child_count()):
		grid.get_child(idx).queue_free()
	for item in db.items:
		if group > 0 and item.group != group:
			continue
		for key in headings:
			var cell = cell_scene.instance()
			cell.set_text(get_cell_content(item, key), key == "url")
			grid.add_child(cell)


func add_bars():
	var num_bars_existing = $BG/VBox.get_child_count()
	if num_bars_existing == 0:
		var bar = ColorRect.new()
		bar.color = light_color
		bar.rect_min_size = Vector2(grid.rect_size.x, row_height)
		$BG/VBox.add_child(bar)
		num_bars_existing = 1
	var num_bars_needed = int(round((grid.rect_size.y - heading_height) / row_height))
	var to_add = num_bars_needed - num_bars_existing
	if to_add > 0:
		var bar = $BG/VBox.get_child(0)
		var color_idx = num_bars_existing
		for n in to_add:
			bar = bar.duplicate()
			bar.color = [light_color, dark_color][color_idx % 2]
			color_idx += 1
			$BG/VBox.add_child(bar)
	if to_add < 0:
		for idx in range(num_bars_existing + to_add, num_bars_existing):
			$BG/VBox.get_child(idx).queue_free()


func get_cell_content(data, key):
	match key:
		"modified":
			var date = OS.get_datetime_from_unix_time(data[key])
			return Date.format(date, settings.date_format)
		"notes":
			var idx = data[key].find("\n")
			if idx > -1:
				return data[key].left(idx)
	return data[key]


func test():
	settings = Settings.new()
	database = Database.new()
	add_groups()
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
	populate_grid(database, "", false, 0)


func _ready():
	grid = $SC/Grid
	for key in headings:
		var heading = heading_scene.instance()
		heading.set_sort_mode(heading.NONE)
		heading.find_node("Label").text = headings[key]
		heading.db_key = key
		heading.connect("clicked", self, "heading_clicked")
		grid.add_child(heading)
	emit_signal("action", "hello", null)
	test()


func init(_data):
	visible = true


func add_groups():
	for group in settings.groups:
		var gb = group_button.instance()
		gb.id = group
		gb.text = settings.groups[group]
		var _e = gb.connect("group_button_pressed", self, "set_group")
		$Groups.add_child(gb)


func set_group(id):
	current_group = id
	populate_grid(database, current_key, current_reverse_state, current_group)


func heading_clicked(heading: Heading):
	var idx = 0
	for key in headings:
		if key != heading.db_key:
			grid.get_child(idx).set_sort_mode(heading.NONE)
		idx += 1
	populate_grid(database, heading.db_key, bool(heading.sort_mode), current_group)


func _on_Grid_item_rect_changed():
	heading_height = grid.get_child(0).rect_size.y
	row_height = grid.get_children()[-1].rect_size.y
	# Position below the grid header row
	$BG/VBox.rect_position = grid.rect_global_position + Vector2(0, heading_height)
	update_bars = true


func _process(_delta):
	if update_bars:
		add_bars()
		update_bars = false


func _on_DataForm_visibility_changed():
	$BG/VBox.visible = visible
