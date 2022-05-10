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
	aes.start(AESContext.MODE_CBC_ENCRYPT, salted_key(settings, key), iv)
	data = aes.update(pad_data(pdata.to_utf8()))
	aes.finish()


func decode_data(key, settings):
	var decrypted
	aes.start(AESContext.MODE_CBC_DECRYPT, salted_key(settings, key), iv)
	decrypted = aes.update(data)
	aes.finish()
	decrypted.resize(decrypted.size() - decrypted[-1])
	return decrypted


func pad_data(d: PoolByteArray):
	# Resize to multiple of 16 bytes and record the pad_size in the padded bytes
	var pad_size = IV_SIZE - d.size() % IV_SIZE
	if pad_size == 0: pad_size = IV_SIZE
	# Pad with known byte values rather than simply resizing 
	for _n in pad_size:
		d.append(pad_size)
	return d


func save_data(settings):
	var _result = ResourceSaver.save(pw_file(settings), self)


func load_data(settings):
	if ResourceLoader.exists(pw_file(settings)):
		return ResourceLoader.load(pw_file(settings))


func salted_key(settings, key):
	# This function allows us to change how we may apply the salt
	return (settings.salt + key).sha256_buffer()


func pw_file(settings):
	return "user://" + settings.pw_file
