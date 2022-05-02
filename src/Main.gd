extends Control

var settings: Settings

func _ready():
	settings = Settings.new()
	var passwords = Passwords.new()
	passwords.test(settings)
	passwords.save_data(settings)
	var pwd = passwords.load_data(settings)
	print(pwd)
