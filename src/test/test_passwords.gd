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
	var key = passwords.salted_key({ "salt": "asalt"}, "mykey")
	assert_true(key is PoolByteArray, "Key is a PoolByteArray")
	assert_true(key.size() > 10, "Key length > 10")
	var key2 = passwords.salted_key({ "salt": "bsalt"}, "mykey")
	assert_ne_shallow(key, key2)

func test_encryption():
	passwords.set_iv()
	passwords.encode_data("mydata", "akey", { "salt": "asalt"})
	assert_true(passwords.data is PoolByteArray, "Data is a PoolByteArray")
	var decoded_data = passwords.decode_data("akey", { "salt": "asalt"})
	assert_eq(decoded_data.get_string_from_utf8(), "mydata")
