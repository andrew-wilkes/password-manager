extends Control

enum { NO_ACTION, NEW, OPEN, SAVE, SAVE_AS, SAVE_INC, QUIT, ABOUT, LICENCES, PWD_GEN, CHG_PW, SETTINGS }
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
var database: Database

onready var file_menu = find_node("File").get_popup()
onready var file_dialog = find_node("FileDialog")
onready var tools_menu = find_node("Tools").get_popup()
onready var help_menu = find_node("Help").get_popup()
onready var content_node = find_node("Content")
onready var alert = find_node("Alert")

var menu_action = NO_ACTION
var state = NO_ACTION
var password = ""

func _ready():
	settings = Settings.new()
	settings = settings.load_data()
	load_passwords()
	database = Database.new()
	configure_menu()
	for child in content_node.get_children():
		var _e = child.connect("action", self, "state_handler")


func state_handler(action, data):
	match state:
		SET_PASSWORD:
			match action:
				ENTER_PRESSED:
					password = data.sha256_text()
					state = ACCESS_DATA
					show_content(form_map[state])
				PASSWORD_TEXT_CHANGED:
					# Evaluate the password strength
					pass
		ENTER_PASSWORD:
			match action:
				ENTER_PRESSED:
					# Try to open the database
					# If error, display alert
					state = ACCESS_DATA
					show_content(form_map[state])
				BROWSE_PRESSED:
					menu_action = OPEN
					do_action()
		ACCESS_DATA:
			pass


func set_title(locked):
	var title = ProjectSettings.get_setting("application/config/name")
	title += " - " + settings.current_file
	if locked:
		title += " [LOCKED]"
	if OS.is_debug_build():
		title += " (DEBUG)"
	OS.set_window_title(title)


func load_passwords():
	passwords = Passwords.new()
	var pwd = passwords.load_data(settings)
	if pwd == null:
		passwords.set_iv()
		state = SET_PASSWORD
		show_content(form_map[state], "")
	else:
		if pwd is Passwords:
			passwords = pwd
			set_title(LOCKED)
			state = ENTER_PASSWORD
			show_content(form_map[state], settings.current_file)
		else:
			alert.show_message("Error opening password data file")


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
	file_menu.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	file_menu.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	tools_menu.add_item("Password Generator", PWD_GEN)
	tools_menu.add_item("Change Password", CHG_PW)
	tools_menu.add_item("Settings", SETTINGS)
	tools_menu.connect("id_pressed", self, "_on_ToolsMenu_id_pressed")
	
	help_menu.add_item("About", ABOUT)
	help_menu.add_separator()
	help_menu.add_item("Licences", LICENCES)
	help_menu.connect("id_pressed", self, "_on_HelpMenu_id_pressed")


func _on_FileMenu_id_pressed(id):
	menu_action = id
	match id:
		NEW:
			passwords.save_data(settings)
			settings.current_file = ""
			load_passwords()
		OPEN:
			do_action()
		SAVE:
			do_action()
		SAVE_AS:
			menu_action = SAVE
			settings.current_file = ""
			do_action()
		SAVE_INC:
			# Append an increment number to the file name and save
			pass
		QUIT:
			get_tree().quit()


func _on_ToolsMenu_id_pressed(id):
	match id:
		PWD_GEN:
			pass
		CHG_PW:
			state = SET_PASSWORD
			show_content(form_map[state], "")
		SETTINGS:
			pass


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
			if settings.current_file == "":
				file_dialog.current_dir = settings.last_dir
				file_dialog.current_file = ""
				file_dialog.mode = FileDialog.MODE_SAVE_FILE
				file_dialog.popup_centered()
			else:
				save_data()


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()


# Handle shutdown of App
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_data()


func save_data():
	settings.save_data()
	passwords.save_data(settings)


func _on_File_pressed():
	file_menu.show()


func _on_Tools_pressed():
	tools_menu.show()


func _on_Help_pressed():
	help_menu.show()


func _on_FileDialog_file_selected(path):
	if path.rstrip("/") == path.get_base_dir():
		alert.show_message("No filename was specified")
		return
	settings.current_file = path.get_file()
	settings.last_dir = path.get_base_dir()
	if menu_action == SAVE:
		passwords.save_data(settings)
	else:
		load_passwords()
