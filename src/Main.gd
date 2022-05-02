extends Control

var settings: Settings

func _ready():
	settings = Settings.new()
	var passwords = Passwords.new(settings)
	passwords.test()
	
