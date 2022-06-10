extends WindowDialog

signal group_removed(group_id)
signal error(msg)

const MIN_KEY_LENGTH = 8

var settings

onready var date_format = $M/VB/DateFormat
onready var keys: OptionButton = $M/VB/Keys
onready var groups: OptionButton = $M/VB/Groups

func open(_settings):
	settings = _settings
	date_format.text = settings.date_format
	popup_centered()
	call_deferred("set_panel_size")
	test()
	var idx = 0
	for group_id in settings.groups:
		groups.add_item(settings.groups[group_id])
		groups.set_item_id(idx, group_id)
		idx += 1


func test():
	for n in 4:
		var key = str(n).md5_text()
		keys.add_item(key)
		settings.keys.append(key)


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
	if txt.empty():
		emit_signal("error", "Ignoring empty entry")
	else:
		if adding:
			add_group(txt)
		else:
			edit_group(txt)


func add_group(group_name):
	if group_name in settings.groups.values():
		emit_signal("error", "Group already in the list")
	else:
		var max_id = settings.groups.keys().max()
		var group_id = 1 if max_id == null else max_id + 1
		settings.groups[group_id] = group_name
		groups.add_item(group_name)
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
	$GroupDelete.popup_centered()


func _on_GroupDelete_confirmed():
	var group_id = groups.get_selected_id()
	var _e = settings.groups.erase(group_id)
	groups.remove_item(groups.selected)
	if groups.get_item_count() > 0:
		select_next_option(groups)
	emit_signal("group_removed", group_id)


func _on_EnterKey_pressed():
	$KeyEntry.open("Enter Key")


func _on_KeyEntry_ok_pressed(key_text, _adding):
	if key_text.length() < MIN_KEY_LENGTH:
		emit_signal("error", "Key must be longer than " + str(MIN_KEY_LENGTH) + " characters")
	else:
		if key_text in settings.keys:
			emit_signal("error", "Key already in the list")
		else:
			settings.keys.append(key_text)
			keys.add_item(key_text)
			var idx = keys.get_item_count() - 1
			keys.select(idx)


func _on_DeleteKey_pressed():
	$KeyDelete.popup_centered()


func _on_KeyDelete_confirmed():
	var _e = settings.keys.remove(keys.selected)
	if keys.get_item_count() == 1:
		keys.add_item("new")
	keys.remove_item(keys.selected)
	select_next_option(keys)


func select_next_option(ob: OptionButton):
	for idx in ob.get_item_count():
		if idx != ob.selected:
			ob.select(idx)
			return
	# Workaround to be able to select the last remaining item
	ob.add_item(ob.get_item_text(0))
	ob.select(1)
	ob.remove_item(0)
	ob.select(0)
