extends Control

var settings: Settings
var passwords: Passwords

func _ready():
	settings = Settings.new()
	settings = settings.load_data()
	passwords = Passwords.new()
	var pwd = passwords.load_data(settings)
	if pwd == null:
		passwords.set_iv()
	else:
		passwords = pwd
	print("ok")


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()


# Handle shutdown of App
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		settings.save_data()
		passwords.save_data(settings)
