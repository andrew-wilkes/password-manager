extends Resource

class_name Passwords

const IV_SIZE = 16 # Bytes
const HASH_SIZE = 32 # Bytes

export(PoolByteArray) var data
export var iv := PoolByteArray()

var aes = AESContext.new()
var decrypted_data

func set_iv():
	iv.resize(IV_SIZE)
	for n in IV_SIZE:
		iv.set(n, randi() % 0xff)


# This step is to obscure the data, so even if a cracker brute-forces the
# correct salted key they will not see recognizable data, and hence not
# know that they identified the key (hopefully).
func pre_encode_data(pdata, salt):
	aes.start(AESContext.MODE_ECB_ENCRYPT, salt.sha256_buffer())
	var byte_data = pad_data(pdata)
	data = aes.update(byte_data)
	aes.finish()


func post_encode_data(salt, key):
	aes.start(AESContext.MODE_CBC_ENCRYPT, salted_key(salt, key), iv)
	data = aes.update(data)
	aes.finish()


func pre_decode_data(salt, key):
	aes.start(AESContext.MODE_CBC_DECRYPT, salted_key(salt, key), iv)
	decrypted_data = aes.update(data)
	aes.finish()


func post_decode_data(salt):
	aes.start(AESContext.MODE_ECB_DECRYPT, salt.sha256_buffer())
	decrypted_data = aes.update(decrypted_data)
	aes.finish()
	decrypted_data.resize(decrypted_data.size() - decrypted_data[-1])


func pad_data(d: PoolByteArray):
	# Resize to multiple of 16 bytes and record the pad_size in the padded bytes
	var pad_size = IV_SIZE - d.size() % IV_SIZE
	if pad_size == 0: pad_size = IV_SIZE
	# Pad with known byte values rather than simply resizing 
	for _n in pad_size:
		d.append(pad_size)
	return d


func save_data(settings):
	var failed = true
	if settings.current_file.empty():
		return failed
	var bytes = iv
	bytes.append_array(data)
	var file = File.new()
	if file.open(password_filename(settings), File.WRITE) == OK:
		file.store_buffer(bytes)
		file.close()
		failed = false
	return failed


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


func salted_key(salt, key):
	# This function allows us to change how we may apply the salt
	return (salt + key).sha256_buffer()


func password_filename(settings):
	return settings.last_dir + "/" + settings.current_file


# This function will be used to verify if the decrypted data is comprehensible or not.
func verify_data(decoded_data: PoolByteArray):
	var verified = false
	if decoded_data.size() > HASH_SIZE:
		var hash_bytes = decoded_data.subarray(0, HASH_SIZE - 1)
		decrypted_data = decoded_data.subarray(HASH_SIZE, -1)
		var db_hash = hash_bytes(decrypted_data)
		var crypto = Crypto.new()
		if crypto.constant_time_compare(hash_bytes, db_hash):
			verified = true
	return verified


static func hash_bytes(b: PoolByteArray):
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(b)
	# Get the computed hash.
	return ctx.finish()
