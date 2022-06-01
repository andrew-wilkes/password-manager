extends Resource

class_name Passwords

const IV_SIZE = 16 # Bytes
const HASH_SIZE = 32 # Bytes

export(PoolByteArray) var data
export var iv := PoolByteArray()

var aes = AESContext.new()

func set_iv():
	iv.resize(IV_SIZE)
	for n in IV_SIZE:
		iv.set(n, randi() % 0xff)


# This step is to obscure the data, so even if a cracker brute-forces the
# correct salted key they will not see recognizable data, and hence not
# know that they identified the key (hopefully).
func pre_encode_data(pdata, settings):
	aes.start(AESContext.MODE_ECB_ENCRYPT, settings.salt.sha256_buffer())
	data = aes.update(pad_data(pdata.to_utf8()))
	aes.finish()


func post_encode_data(key, settings):
	aes.start(AESContext.MODE_CBC_ENCRYPT, salted_key(settings, key), iv)
	data = aes.update(data)
	aes.finish()


func pre_decode_data(key, settings):
	aes.start(AESContext.MODE_CBC_DECRYPT, salted_key(settings, key), iv)
	data = aes.update(data)
	aes.finish()


func post_decode_data(settings):
	aes.start(AESContext.MODE_ECB_DECRYPT, settings.salt.sha256_buffer())
	var decrypted = aes.update(data)
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
	var bytes = iv
	bytes.append_array(data)
	var file = File.new()
	if file.open(password_filename(settings), File.WRITE) == OK:
		file.store_buffer(bytes)
		file.close()


func load_data(settings):
	var loaded = false
	var file = File.new()
	if file.file_exists(password_filename(settings)):
		if file.open(password_filename(settings), File.READ) == OK:
			if file.get_len() > IV_SIZE:
				iv = file.get_buffer(IV_SIZE)
				data = file.get_buffer(file.get_len() - IV_SIZE)
				loaded = true
			file.close()
	return loaded


func salted_key(settings, key):
	# This function allows us to change how we may apply the salt
	return (settings.salt + key).sha256_buffer()


func password_filename(settings):
	return settings.last_dir + "/" + settings.current_file


func verify_data(decoded_data: PoolByteArray):
	var result = { "verified": false, "data": null }
	if decoded_data.size() > HASH_SIZE:
		var hash_bytes = decoded_data.subarray(0, HASH_SIZE - 1)
		result.data = decoded_data.subarray(HASH_SIZE, -1)
		var db_hash = hash_bytes(result.data)
		if [db_hash].hash() == [hash_bytes].hash():
			result.verified = true
	return result


func hash_bytes(b: PoolByteArray):
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(b)
	# Get the computed hash.
	return ctx.finish()
