extends Control

func _ready():
	var settings = Settings.new()
	test_get_char(settings)
	test_generate_salt(settings)
	test_enc_dec(settings)


func test_enc_dec(settings):
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


func test_get_char(settings):
	var chrs = PoolStringArray()
	for n in 36:
		chrs.append(settings.get_char(n))
	prints("Chars:", chrs)


func test_generate_salt(settings):
	for n in 10:
		prints("Salt:", settings.generate_salt())

