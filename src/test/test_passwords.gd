extends GutTest

var passwords = Passwords.new()

func test_set_iv():
	passwords.set_iv()
	assert_true(passwords.iv is PoolByteArray, "IV is a PoolByteArray")
	assert_true(passwords.iv.size() == 16, "IV size is 16 bytes")

func test_pad_data():
	var padded_data = passwords.pad_data([0])
	assert_eq(padded_data.size(), 16)
	assert_eq(padded_data[-1], 15)
	padded_data = passwords.pad_data(padded_data)
	assert_eq(padded_data.size(), 32)
	assert_eq(padded_data[16], 16)
	assert_eq(padded_data[-1], 16)

func test_salted_key():
	var key = passwords.salted_key("asalt", "mykey")
	assert_true(key is PoolByteArray, "Key is a PoolByteArray")
	assert_true(key.size() > 10, "Key length > 10")
	var key2 = passwords.salted_key("bsalt", "mykey")
	assert_ne_shallow(key, key2)

func test_encryption():
	var salt = "asalt"
	var key = "akey"
	passwords.set_iv()
	passwords.pre_encode_data("mydata".to_utf8(), salt)
	assert_true(passwords.data is PoolByteArray, "Data is a PoolByteArray")
	passwords.post_encode_data(salt, key)
	assert_true(passwords.data is PoolByteArray, "Data is a PoolByteArray")
	passwords.pre_decode_data(salt, key)
	assert_true(passwords.decrypted_data is PoolByteArray, "Data is a PoolByteArray")
	passwords.post_decode_data(salt)
	assert_eq(passwords.decrypted_data.get_string_from_utf8(), "mydata")

func test_save_load():
	var settings = { "last_dir": "./test", "current_file": "test.pwd" }
	var fname = "./test/test.pwd"
	assert_eq(passwords.password_filename(settings), fname)
	passwords.set_iv()
	var iv = passwords.iv
	passwords.data = passwords.iv
	var failed = passwords.save_data(settings)
	assert_false(failed)
	assert_file_exists(fname)
	passwords.iv.invert()
	passwords.data = passwords.iv
	assert_true(passwords.load_data(settings))
	assert_eq(passwords.iv, iv)
	assert_eq(passwords.data, iv)
	gut.file_delete(fname) # Doesn't delete file

func test_hash_bytes():
	var db = PoolByteArray([1,2,5,6,7])
	var x = passwords.hash_bytes(db)
	assert_eq(x[0], 53)

func test_verify_data():
	var txt = "yabbado"
	# Get a PoolByteArray of the text data
	var byte_data = txt.to_utf8()
	var the_data = txt.sha256_buffer()
	var bytes = txt.sha256_text().to_utf8()
	print(the_data)
	print(bytes)
	the_data.append_array(byte_data)
	var result = passwords.verify_data(the_data)
	assert_true(result)
	result = passwords.verify_data(the_data.subarray(8,-1))
	assert_false(result)
