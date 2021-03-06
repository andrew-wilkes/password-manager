extends WindowDialog

signal update_groups
signal update_item_list

var headings = {
	"groups": "Groups",
	"title": "Title",
	"username": "Username",
	"password": "Password",
	"url": "URL",
	"notes": "Notes",
	"created": "Created",
	"modified": "Modified",
}

var column_assignments
var settings
var database
var num_cols = 0
var csv

func _ready():
	var idx = 0
	for heading in headings.values():
		var label = Label.new()
		var label2 = label.duplicate()
		label2.text = heading
		label2.modulate = Color(0.7, 0.7, 0.7)
		$M/VB/SC/Grid.add_child(label2)
		label.text = heading + ":"
		$M/VB/Grid.add_child(label)
		var button = OptionButton.new()
		$M/VB/Grid.add_child(button)
		button.connect("item_selected", self, "option_selected", [idx])
		idx += 1
	# Add 2 rows of labels to grid
	for n in headings.size() * 2:
		$M/VB/SC/Grid.add_child(Label.new())
	if get_parent().name == "root":
		test()


func test():
	var _csv = [PoolStringArray(["AAA","BBB","CCC","DDD"]),PoolStringArray(["aaa","bbb","ccccccccccccccccccccc","ddd"]),PoolStringArray(["xxx","yyy", 0])]
	open("path-to-file.csv", _csv, null, { date_format = "YYYY-MM-DD" })


func option_selected(id, idx):
	if id > 0:
		column_assignments[idx] = id - 1
	else:
		column_assignments[idx] = null
	update_preview()


func update_preview():
	# Show up to 2 rows
	var rn = -1 if $M/VB/IgnoreFirstRow.pressed else 0
	var label_offset = 0
	for row in csv:
		if rn >= 0:
			label_offset += headings.size()
			for idx in headings.size():
				var label = $M/VB/SC/Grid.get_child(label_offset + idx)
				var column = column_assignments[idx]
				if column != null and column < row.size():
					label.text = format_content(row[column], headings.keys()[idx])
				else:
					label.text = ""
		if rn == 1:
			break
		rn += 1


func format_content(data, key):
	match key:
		"created", "modified":
			if data.is_valid_integer():
				var date = OS.get_datetime_from_unix_time(int(data))
				data = Date.format(date, settings.date_format)
			else:
				data = ""
		"notes":
			var idx = data.find("\n")
			if idx > -1:
				data = data.left(idx)
	return data


func open(path, _csv, db, _settings):
	$M/VB/HB/Path.text = path
	csv = _csv
	settings = _settings
	database = db
	# Establish the number of data columns
	num_cols = 0
	for row in csv:
		if row.size() > num_cols:
			num_cols = row.size()
	column_assignments = []
	column_assignments.resize(headings.size())
	$M/VB/HB/ColRow.text = str(num_cols) + " columns x " + str(_csv.size()) + " rows"
	var idx = 0
	# Set up option buttons
	for button in $M/VB/Grid.get_children():
		if button is Label:
			continue
		button.clear()
		button.add_item("None")
		for n in num_cols:
			button.add_item("Column " + str(n + 1))
		# Pre-select the buttons
		if idx < num_cols:
			button.select(idx + 1)
			column_assignments[idx] = idx
		idx += 1
	update_preview()
	call_deferred("set_panel_size")


func set_panel_size():
	rect_size = $M.rect_size
	popup_centered()
	var size = rect_size
	yield(get_tree(), "idle_frame")
	rect_size = $M.rect_size
	rect_position -= (rect_size - size) / 2


func _on_IgnoreFirstRow_pressed():
	update_preview()


func _on_OK_pressed():
	# Add to groups
	var groups = {}
	var group_column = column_assignments[0]
	if group_column != null:
		var rn = -1 if $M/VB/IgnoreFirstRow.pressed else 0
		var update_groups = false
		for row in csv:
			if rn >= 0:
				if group_column < row.size() and not row[group_column].empty():
					groups[row[group_column]] = true
					update_groups = true
			rn += 1
		for group_name in groups.keys():
			settings.add_group(group_name)
		if update_groups:
			emit_signal("update_groups")
	
	# Add to database
	var rn = -1 if $M/VB/IgnoreFirstRow.pressed else 0
	for row in csv:
		if rn >= 0:
			var record = Record.new()
			var idx = 0
			for key in headings.keys():
				var col = column_assignments[idx]
				if col != null and col < row.size():
					var data = row[col]
					match key:
						"groups":
							# replace value with id number of the group
							for id in settings.groups:
								if settings.groups[id] == data:
									data = [id]
									break
						"created", "modified":
							if data.is_valid_integer():
								data = int(data)
							else:
								continue
					record.data[key] = data
				idx += 1
			set_password_strength(record.data)
			database.items.append(record.data)
		rn += 1
	if rn >= 0:
		emit_signal("update_item_list")
	hide()


func set_password_strength(item):
	if not item.password.empty():
		var user_inputs = []
		if not item.username.empty():
			user_inputs.append(item.username)
		item.strength = ZXCVBN.zxcvbn(item.password, user_inputs)["score"]
