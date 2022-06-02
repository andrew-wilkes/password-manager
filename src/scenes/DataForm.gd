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

func populate_grid(db: Database, key, reverse, group):
	db.order_items(key, reverse)
	for idx in range(grid.columns, grid.get_child_count()):
		grid.get_child(idx).queue_free()
	for item in db.items:
		var record: Record = item
		if group > 0 and record.data.group != group:
			continue
		for key in headings:
			var cell = cell_scene.instance()
			cell.set_text(get_cell_content(record.data, key))
			grid.add_child(cell)
	#call_deferred("add_bars")


func add_bars():
	var height = grid.get_child(0).rect_size.y
	$BG/VBox.rect_position = grid.rect_global_position + Vector2(0, height)
	$BG/VBox.rect_size = grid.rect_size
	var bar = ColorRect.new()
	bar.color = light_color
	bar.rect_min_size = Vector2(grid.rect_size.x, height)
	bar.rect_position = Vector2(0, height)
	bar.show_behind_parent = true
	$BG/VBox.add_child(bar)
	#[light_color, dark_color][color_type]

func get_cell_content(data, key):
	match key:
		"modified":
			var date = OS.get_datetime_from_unix_time(data[key])
			return Date.format(date, settings.date_format)
		"notes":
			var idx = data[key].find("\n")
			if idx > -1:
				return data[key].left(idx)
			else:
				return data[key]
		_:
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
	db.items.append(r1)
	for n in 8:
		var r = Record.new()
		r.data = r1.data.duplicate()
		db.items.append(r)
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
	# Using a scroll container stops this control from expanding to fill the parent area
	rect_min_size = get_parent().rect_size


func heading_clicked(heading):
	print(heading.db_key)
	emit_signal("action", "heading_clicked", heading)
