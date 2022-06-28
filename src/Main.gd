extends Control

enum { NO_ACTION, NEW, OPEN, SAVE, SAVE_AS, SAVE_INC, IMPORT, QUIT, ABOUT, LICENCES, PWD_GEN, CHG_PW }
enum { LOAD_CSV, LOAD_KP }
enum { UNLOCKED, LOCKED }
enum { SET_PASSWORD, ENTER_PASSWORD, ACCESS_DATA }
enum { ENTER_PRESSED, PASSWORD_TEXT_CHANGED, BROWSE_PRESSED }

const form_map = {
	SET_PASSWORD: "SetPasswordForm",
	ENTER_PASSWORD: "PasswordForm",
	ACCESS_DATA: "DataForm"
}

var settings: Settings
var passwords: Passwords
export(Texture) var menu_icon

onready var file_menu = find_node("File").get_popup()
onready var file_dialog = find_node("FileDialog")
onready var tools_menu = find_node("Tools").get_popup()
onready var help_menu = find_node("Help").get_popup()
onready var content_node = find_node("Content")
onready var alert = find_node("Alert")
onready var data_form = find_node("DataForm")

var menu_action = NO_ACTION
var state = NO_ACTION
var password = ""
var locked: bool

func _ready():
	randomize()
	get_tree().set_auto_accept_quit(false)
	var _e = get_tree().get_root().connect("size_changed", self, "viewport_size_changed")
	settings = Settings.new()
	settings = settings.load_data()
	configure_menu()
	load_passwords()
	for child in content_node.get_children():
		_e = child.connect("action", self, "state_handler")


func state_handler(action, data):
	match state:
		SET_PASSWORD:
			match action:
				ENTER_PRESSED:
					password = data
					state = ACCESS_DATA
					show_content(form_map[state],\
						 {settings = settings, database = Database.new()})
					set_locked(false)
				PASSWORD_TEXT_CHANGED:
					# Decided not to evaluate the main password strength since a key is also applied
					pass
		ENTER_PASSWORD:
			match action:
				ENTER_PRESSED:
					# Try to open the database
					password = data
					passwords.pre_decode_data(settings.keys[settings.key_idx], password)
					passwords.post_decode_data(settings.keys[settings.key_idx])
					# If error, display alert
					if passwords.verify_data(passwords.decrypted_data):
						state = ACCESS_DATA
						var parse_obj = JSON.parse(passwords.decrypted_data.get_string_from_utf8())
						var db = Database.new()
						if typeof(parse_obj.result) == TYPE_ARRAY:
							db.items = parse_obj.result
						show_content(form_map[state], { "settings": settings, "database": db })
						set_locked(false)
					else:
						alert.show_message("Invalid password or key")
				BROWSE_PRESSED:
					menu_action = OPEN
					do_action()


func set_title():
	var title = ProjectSettings.get_setting("application/config/name")
	title += " - " + settings.current_file
	if locked:
		title += " [LOCKED]"
	if OS.is_debug_build():
		title += " (DEBUG)"
	OS.set_window_title(title)


func load_passwords():
	set_locked(true)
	passwords = Passwords.new()
	if passwords.load_data(settings):
		state = ENTER_PASSWORD
		show_content(form_map[state], settings.current_file)
	else:
		passwords.set_iv()
		state = SET_PASSWORD
		show_content(form_map[state], "")


func show_content(target_name, data = null):
	for child in content_node.get_children():
		if child.name == target_name:
			child.init(data)
		else:
			child.hide()


func configure_menu():
	file_menu.add_item("New", NEW, KEY_MASK_CTRL | KEY_N)
	file_menu.add_item("Open", OPEN, KEY_MASK_CTRL | KEY_O)
	file_menu.add_separator()
	file_menu.add_item("Save", SAVE, KEY_MASK_CTRL | KEY_S)
	file_menu.add_item("Save As...", SAVE_AS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	file_menu.add_item("Save Increment", SAVE_INC, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_I)
	file_menu.add_separator()
	file_menu.add_submenu_item("Import", "../ImportMenu")
	file_menu.add_separator()
	file_menu.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	file_menu.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	tools_menu.add_item("Password Generator", PWD_GEN)
	tools_menu.add_item("Change Password", CHG_PW)
	tools_menu.connect("id_pressed", self, "_on_ToolsMenu_id_pressed")

	help_menu.add_icon_item(menu_icon, "About", ABOUT)
	help_menu.add_separator()
	help_menu.add_item("Licences", LICENCES)
	help_menu.connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	
	$M/Menu/File/ImportMenu.add_item("KeePass 2 Database...", LOAD_KP)
	$M/Menu/File/ImportMenu.add_item("CSV File...", LOAD_CSV)
	$M/Menu/Settings.show()


func set_locked(lock):
	locked = lock
	# Enable/disable Save menu items
	for idx in [3, 4, 5, 7]:
		file_menu.set_item_disabled(idx, lock)
		file_menu.set_item_shortcut_disabled(idx, lock)
	tools_menu.set_item_disabled(1, lock)
	tools_menu.set_item_shortcut_disabled(1, lock)
	set_title()


func _on_FileMenu_id_pressed(id):
	menu_action = id
	match id:
		NEW:
			if locked:
				settings.current_file = ""
				load_passwords()
			else:
				# Save before setting new data
				if save_passwords():
					settings.current_file = ""
					load_passwords()
		OPEN:
			if locked:
				do_action()
			else:
				if save_passwords():
					do_action()
		SAVE:
			do_action()
		SAVE_AS:
			menu_action = SAVE
			settings.current_file = ""
			do_action()
		SAVE_INC:
			# Append an increment number to the file name and save
			settings.current_file = Utility.increment_filename(settings.current_file)
			set_title()
			menu_action = SAVE
			do_action()
		QUIT:
			save_and_quit()


func save_passwords():
	var result = true
	if passwords.save_data(settings):
		alert.show_message("Failed to save passwords to file")
		result = false
	return result


func _on_ToolsMenu_id_pressed(id):
	match id:
		PWD_GEN:
			$Popups/PasswordGenerator.open()
		CHG_PW:
			state = SET_PASSWORD
			show_content(form_map[state], "")


func _on_HelpMenu_id_pressed(id):
	match id:
		ABOUT:
			find_node("About").popup_centered()
		LICENCES:
			find_node("Licences").popup_centered()


func do_action():
	match menu_action:
		OPEN:
			file_dialog.current_dir = settings.last_dir
			file_dialog.current_file = settings.current_file
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.popup_centered()
		SAVE:
			if locked: return
			if settings.last_dir == "" or settings.current_file == "":
				file_dialog.current_dir = settings.last_dir
				file_dialog.current_file = ""
				file_dialog.mode = FileDialog.MODE_SAVE_FILE
				file_dialog.popup_centered()
			else:
				update_password_data()
				if passwords.save_data(settings):
					alert.show_message("Error saving file")


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			save_and_quit()


# Handle shutdown of App
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_and_quit()


func save_and_quit():
	settings.save_data()
	if locked or data_form.database == null:
		get_tree().quit()
	else:
		update_password_data()
		if passwords.save_data(settings):
			$Popups/ConfirmQuit.popup_centered()
		else:
			get_tree().quit()


func update_password_data():
	var serialized_data =  JSON.print(data_form.database.items)
	var the_data = serialized_data.sha256_buffer()
	the_data.append_array(serialized_data.to_utf8())
	passwords.pre_encode_data(the_data, settings.keys[settings.key_idx])
	passwords.post_encode_data(settings.keys[settings.key_idx], password)


func _on_File_pressed():
	file_menu.show()


func _on_Tools_pressed():
	tools_menu.show()


func _on_Settings_pressed():
	$Popups/Settings.open(settings)


func _on_Help_pressed():
	help_menu.show()


func _on_FileDialog_file_selected(path):
	if file_ok(path):
		settings.current_file = path.get_file()
		set_title()
		if menu_action == SAVE:
			var _e = save_passwords()
		else:
			load_passwords()


func file_ok(path):
	var ok = true
	if path.rstrip("/") == path.get_base_dir():
		alert.show_message("No filename was specified")
		ok = false
	settings.last_dir = path.get_base_dir()
	return ok


func _on_Content_resized():
	find_node("DataForm").rect_min_size = content_node.rect_size


func viewport_size_changed():
	# Prevent the scroll area from being clamped to a minimum size
	$Content/DataForm.rect_min_size = Vector2.ZERO


func _on_Settings_group_removed(group_id):
	$Content/DataForm.remove_group(group_id)


func _on_ConfirmQuit_confirmed():
	get_tree().quit()


func _on_LoadKeePassFile_file_selected(path):
	if file_ok(path):
		var file = File.new()
		if file.open(path, File.READ) == OK:
			var data = file.get_buffer(file.get_len())
			file.close()
			file_menu.hide()
			if data != null and data.size() > 0:
				$Content/DataForm.keepass_import(path, data)


func _on_LoadCSVFile_file_selected(path):
	if file_ok(path):
		var file = File.new()
		if file.open(path, File.READ) == OK:
			var csv = []
			while true:
				var csv_line = file.get_csv_line()
				if csv_line[0].empty():
					break
				csv.append(csv_line)
			$Content/DataForm.csv_import(path, csv)


func _on_ImportMenu_id_pressed(id):
	match id:
		LOAD_CSV:
			$Popups/LoadCSVFile.current_dir = settings.last_dir
			$Popups/LoadCSVFile.popup_centered()
		LOAD_KP:
			$Popups/LoadKeePassFile.current_dir = settings.last_dir
			$Popups/LoadKeePassFile.popup_centered()


func _on_LoadCSVFile_popup_hide():
	file_menu.hide()


func _on_LoadKeePassFile_popup_hide():
	file_menu.hide()
