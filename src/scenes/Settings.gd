extends WindowDialog

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
	for n in 4:
		groups.add_item("Group: " + str(n))


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
