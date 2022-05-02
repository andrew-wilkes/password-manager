extends Control

var settings: Settings

func _ready():
	settings = Settings.new()
	settings = settings.load_data()
	#settings.save_data()
	var passwords = Passwords.new()
	passwords.test(settings)
	passwords.save_data(settings)
	var pwd = passwords.load_data(settings)
	print(pwd)
