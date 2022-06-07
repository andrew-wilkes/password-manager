extends WindowDialog

signal delete_item(item)

var settings
var item

func open(_item, _settings):
	settings = _settings
	item = _item
	popup_centered()
	call_deferred("set_panel_size")
	$M/VB/HB/Title.text = item.title
	$M/VB/Username.text = item.username
	$M/VB/HB3/URL.text = item.url
	set_secret(item.reveal)
	$M/VB/HB2/Password.text = item.password
	$M/VB/Notes.text = item.notes
	$M/VB/HB4/Time/Created.text = get_date(item.created)
	$M/VB/HB4/Time/Modified.text = get_date(item.modified)
	$M/VB/HB4/Time/Accessed.text = get_date(item.accessed)
	item.accessed = OS.get_unix_time()
	$M/VB/HB4/Time/Remind.text = get_date(item.remind)
	$M/VB/HB4/Time/Expire.text = get_date(item.expire)


func get_date(time_secs):
	if time_secs == 0: return ""
	var date = OS.get_datetime_from_unix_time(time_secs)
	return Date.format(date, settings.date_format)


func update_modified():
	item.modified = OS.get_unix_time()
	$M/VB/HB4/Time/Modified.text = get_date(item.modified)


func set_panel_size():
	rect_size = $M.rect_size


func _on_Show_pressed():
	item.reveal = true
	set_secret(item.reveal)


func _on_Hide_pressed():
	item.reveal = false
	set_secret(item.reveal)


func set_secret(reveal):
	$M/VB/HB2/Password.secret = not reveal
	$M/VB/HB2/C1/Show.visible = not reveal
	$M/VB/HB2/C1/Hide.visible = reveal


func _on_Title_text_changed(new_text):
	item.title = new_text
	update_modified()


func _on_Username_text_changed(new_text):
	item.username = new_text
	update_modified()


func _on_Password_text_changed(new_text):
	item.password = new_text
	# Check password strength and show alerts
	# Update the tick etc.
	update_modified()


func _on_URL_text_changed(new_text):
	# May want to add some kind of filtering to the URL here to strip out tracking IDs etc.
	# The user may copy and paste a URL for example
	# Could have a settings option for the level of filtering
	item.url = new_text
	update_modified()


func _on_Notes_text_changed():
	item.notes = $M/VB/Notes.text
	update_modified()


func _on_Delete_pressed():
	$Confirm.popup_centered()


func _on_Confirm_confirmed():
	emit_signal("delete_item", item)
	hide()


func _on_WWW_pressed():
	var _e = OS.shell_open($M/VB/HB3/URL.text)
