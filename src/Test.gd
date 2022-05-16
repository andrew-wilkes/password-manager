extends Control

var settings

func _ready():
	settings = Settings.new()
	test_get_char()
	test_generate_salt()
	test_enc_dec()
	#var data = FrequencyLists.data.size()
	#print(data)


func test_enc_dec():
	var passwords = Passwords.new()
	passwords.set_iv()
	prints("IV:", passwords.iv)
	var key = "MyKey"
	var mydata = "Some data"
	passwords.encode_data(mydata, key, settings)
	prints("Data:", passwords.data)
	var decoded = passwords.decode_data(key, settings)
	assert(decoded == mydata.to_utf8())
	print("Passed")


func test_get_char():
	var chrs = PoolStringArray()
	for n in 36:
		chrs.append(settings.get_char(n))
	prints("Chars:", chrs)


func test_generate_salt():
	for n in 10:
		prints("Salt:", settings.generate_salt())



func _on_EraseSettings_pressed():
	var dir = Directory.new()
	if dir.remove(settings.FILE_NAME) == OK:
		$AcceptDialog.dialog_text = "Deleted " + settings.FILE_NAME
	else:
		$AcceptDialog.dialog_text = settings.FILE_NAME + " not found."
	$AcceptDialog.popup_centered()


func _on_ErasePWD_pressed():
	var dir = Directory.new()
	var fn = "user://" + settings.pw_file
	if dir.remove(fn) == OK:
		$AcceptDialog.dialog_text = "Deleted " + fn
	else:
		$AcceptDialog.dialog_text = fn + " not found."
	$AcceptDialog.popup_centered()
