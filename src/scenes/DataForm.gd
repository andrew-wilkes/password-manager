extends VBoxContainer

signal action(id, data)

enum { LIGHT, DARK, HIGHLIGHTED }

export(Color) var light_color
export(Color) var dark_color
export(Color) var highlight_color

var heading_scene = preload("res://scenes/Heading.tscn")
var cell_scene = preload("res://scenes/Cell.tscn")
var grid: GridContainer
var headings = {
	"title": "Title",
	"username": "Username",
	"url": "URL",
	"notes": "Notes",
	"modified": "Modified",
}
var settings: Settings
var bar_height = 0
var update_bars = false

func populate_grid(db: Database, key, reverse, group):
	db.order_items(key, reverse)
	for idx in range(grid.columns, grid.get_child_count()):
		grid.get_child(idx).queue_free()
	for item in db.items:
		if group > 0 and item.group != group:
			continue
		for key in headings:
			var cell = cell_scene.instance()
			cell.set_text(get_cell_content(item, key))
			grid.add_child(cell)


func add_bars():
	var num_bars_existing = $BG/VBox.get_child_count()
	if num_bars_existing == 0:
		var bar = ColorRect.new()
		bar.color = light_color
		bar.rect_min_size = Vector2(grid.rect_size.x, bar_height)
		$BG/VBox.add_child(bar)
		num_bars_existing = 1
	var num_bars_needed = int(round(grid.rect_size.y / bar_height)) - 1
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
	var db = Database.new()
	var r1 = Record.new()
	r1.data.title = "Title of entry"
	r1.data.username = "User1"
	r1.data.url = "https://bing.com"
	r1.data.notes = "Just some notes\nNext line"
	r1.data.modified = OS.get_unix_time()
	db.items.append(r1.data)
	for n in 8:
		var r = Record.new()
		r.data = r1.data.duplicate()
		db.items.append(r.data)
	populate_grid(db, "title", false, 0)


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


func heading_clicked(heading):
	print(heading.db_key)
	emit_signal("action", "heading_clicked", heading)


func _on_Grid_item_rect_changed():
	bar_height = grid.get_child(0).rect_size.y
	# Position below the grid header row
	$BG/VBox.rect_position = grid.rect_global_position + Vector2(0, bar_height)
	update_bars = true


func _process(_delta):
	if update_bars:
		add_bars()
		update_bars = false


func _on_DataForm_visibility_changed():
	$BG/VBox.visible = visible
