extends WindowDialog

var settings

func open(_settings):
	settings = _settings
	popup_centered()
	call_deferred("set_panel_size")


func get_date(time_secs):
	if time_secs == 0: return ""
	var date = OS.get_datetime_from_unix_time(time_secs)
	return Date.format(date, settings.date_format)


func set_panel_size():
	rect_size = $M.rect_size
