extends WindowDialog

signal delete_item(item)

const GOOD_PASSWORD_SCORE = 3

var settings
var item
onready var groups = $M/VB/HB4/VB/Groups
var id_check_box = preload("res://scenes/IDCheckBox.tscn")
var password_check_result = {}


func open(_item, _settings):
	settings = _settings
	item = _item
	add_groups()
	call_deferred("set_panel_size")
	$M/VB/HB/Title.text = item.title
	$M/VB/Username.text = item.username
	$M/VB/HB3/URL.text = item.url
	set_secret(item.reveal)
	$M/VB/HB2/Password.text = item.password
	set_password_score_status()
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
	popup_centered()
	yield(get_tree(), "idle_frame")
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


func add_groups():
	for node in groups.get_children():
		node.queue_free()
	for group_id in settings.groups:
		var cb = id_check_box.instance()
		cb.id = group_id
		cb.text = settings.groups[group_id]
		if group_id in item.groups:
			cb.pressed = true
		cb.connect("toggled", self, "update_groups", [group_id])
		groups.add_child(cb)


func update_groups(selected, id):
	# JSON conversion turns the id into a float value after saving
	if selected:
		item.groups.append(float(id))
	else:
		item.groups.erase(float(id))


func set_password_score_status():
	var good = true if item.strength >= GOOD_PASSWORD_SCORE else false
	$M/VB/HB2/C2/Warn.visible = not good and not item.password.empty()
	$M/VB/HB2/C2/OK.visible = good


func _on_Title_text_changed(new_text):
	item.title = new_text
	update_modified()


func _on_Username_text_changed(new_text):
	item.username = new_text
	update_modified()


func _on_Password_text_changed(new_text):
	item.password = new_text
	$PasswordCheckTimer.start()
	update_modified()


func _on_URL_text_changed(url: String):
	# May want to add some kind of filtering to the URL here to strip out tracking IDs etc.
	# The user may copy and paste a URL for example
	# Could have a settings option for the level of filtering
	url = url.to_lower()
	if not url.begins_with("http"):
		url = "https://" + url
	item.url = url.replace("fbclid=", "")
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
	if not item.url.empty():
		var _e = OS.shell_open(item.url)


func _on_OK_pressed():
	hide()


func _on_PasswordCheckTimer_timeout():
	check_password()


func check_password():
	if not item.password.empty():
		password_check_result = ZXCVBN.zxcvbn(item.password)
		item.strength = password_check_result["score"]
		set_password_score_status()


func show_feedback():
	if password_check_result.empty():
		check_password()
	
	var txt = ""
	if not password_check_result["feedback"]["warning"].empty():
		txt = "Warning: " + password_check_result["feedback"]["warning"] + "\n\n"
	
	var sugs = password_check_result["feedback"]["suggestions"]
	if sugs.size() > 0:
		txt += "Suggestions\n\n"
		txt += PoolStringArray(sugs).join("\n")
	
	if txt.empty():
		if item.strength == GOOD_PASSWORD_SCORE:
			txt = "This is a good password."
		else:
			txt = "This is a great password!"

	$Feedback.dialog_text = txt
	$Feedback.popup_centered()
