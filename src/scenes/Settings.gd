extends WindowDialog

signal group_removed(group_id)

var settings

onready var date_format = $M/VB/DateFormat
onready var keys: OptionButton = $M/VB/Keys
onready var groups: OptionButton = $M/VB/Groups

func open(_settings):
	settings = _settings
	date_format.text = settings.date_format
	popup_centered()
	call_deferred("set_panel_size")
	for n in 4:
		keys.add_item(str(n).md5_text())
	var idx = 0
	for group_id in settings.groups:
		groups.add_item(settings.groups[group_id])
		groups.set_item_id(idx, group_id)
		idx += 1


func get_date(time_secs):
	if time_secs == 0: return ""
	var date = OS.get_datetime_from_unix_time(time_secs)
	return Date.format(date, settings.date_format)


func set_panel_size():
	rect_size = $M.rect_size


func _on_DateFormat_text_changed(new_text):
	# Only allow YMD- characters
	var date = ""
	for chr in new_text.to_upper():
		if chr in "YMD-":
			date += chr
	date_format.text = ""
	date_format.append_at_cursor(date)


func _on_DateFormat_text_entered(new_text):
	settings.date_format = Date.sanitize_date_format(new_text)
	date_format.text = ""
	date_format.append_at_cursor(settings.date_format)


func _on_AddGroup_pressed():
	$GroupText.open("Add Group")


func _on_GroupText_ok_pressed(txt, adding):
	if not txt.empty():
		if adding:
			add_group(txt)
		else:
			edit_group(txt)


func add_group(txt):
	var add = true
	for group_name in settings.groups.values():
		if txt == group_name:
			add = false
			break
	if add:
		var max_id = settings.groups.keys().max()
		var group_id = 1 if max_id == null else max_id + 1
		settings.groups[group_id] = txt
		groups.add_item(txt)
		var idx = groups.get_item_count() - 1
		groups.select(idx)
		groups.set_item_id(idx, group_id)


func edit_group(txt):
	var group_id = groups.get_selected_id()
	settings.groups[group_id] = txt
	groups.set_item_text(groups.selected, txt)


func _on_EditGroup_pressed():
	$GroupText.open("Edit Group", groups.get_item_text(groups.selected), false)


func _on_DeleteGroup_pressed():
	$Confirm.popup_centered()


func _on_Confirm_confirmed():
	var group_id = groups.get_selected_id()
	var _e = settings.groups.erase(group_id)
	groups.remove_item(groups.selected)
	emit_signal("group_removed", group_id)
	call_deferred("select_first_group")


func select_first_group():
	groups.select(0)
