extends Resource

class_name Passwords

const IV_SIZE = 16

export(PoolByteArray) var data
export var iv := PoolByteArray()

var aes = AESContext.new()

func set_iv():
	iv.resize(IV_SIZE)
	for n in IV_SIZE:
		iv.set(n, randi() % 0xff)


func encode_data(pdata, key, settings):
	aes.start(AESContext.MODE_CBC_ENCRYPT, (key + settings.salt).sha256_buffer(), iv)
	data = aes.update(pad_data(pdata.to_utf8()))
	aes.finish()


func decode_data(key, settings):
	var decrypted
	aes.start(AESContext.MODE_CBC_DECRYPT, (key + settings.salt).sha256_buffer(), iv)
	decrypted = aes.update(data)
	aes.finish()
	decrypted.resize(decrypted.size() - decrypted[-1])
	return decrypted


func pad_data(d: PoolByteArray):
	# Resize to multiple of 16 bytes and record the pad_size in the last byte
	var pad_size = IV_SIZE - d.size() % IV_SIZE
	if pad_size == 0: pad_size = IV_SIZE
	d.resize(d.size() + pad_size)
	d[-1] = pad_size
	return d


func save_data(settings):
	var _result = ResourceSaver.save("user://" + settings.pw_file, self)


func load_data(settings):
	if ResourceLoader.exists("user://" + settings.pw_file):
		return ResourceLoader.load("user://" + settings.pw_file)


func test(settings):
	set_iv()
	print("IV: ", iv)
	var key = "MyKey"
	var mydata = "Some data"
	encode_data(mydata, key, settings)
	print("Data: ", data)
	var decoded = decode_data(key, settings)
	assert(decoded == mydata.to_utf8())
