class_name Salsa20

# https://github.com/Daeinar/salsa20/blob/master/salsa.py
# https://en.wikipedia.org/wiki/Salsa20
# https://cr.yp.to/salsa20.html

const mask = 0xffffffff # 32-bit mask
const ascii = "expand 32-byte k"

var state

func _init(key: PoolByteArray, iv: PoolByteArray, pos = [0, 0]):
	# init state
	var k = []
	var n = []
	for i in 8:
		k.append(get_word_from_bytes(key.subarray(i * 4, i * 4 + 3)))
	for i in 2:
		n.append(get_word_from_bytes(iv.subarray(i * 4, i * 4 + 3)))
	var c = []
	for i in 4:
		c.append(get_word_from_bytes(ascii.to_ascii().subarray(i * 4, i * 4 + 3)))
	#[0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
	state = [c[0], k[0], k[1], k[2], 
		 k[3], c[1], n[0], n[1],
		 pos[0], pos[1], c[2], k[4],
		 k[5], k[6], k[7], c[3]]
	pass


func generate_key_stream():
	return get_bytes_from_words(salsa20_block())


# Generate a block of 16 32bit words
func salsa20_block():
	var x = state.duplicate(true)

	# 10 loops × 2 rounds/loop = 20 rounds
	for i in 10:
		# Odd round
		quarter_round(0, 4, 8, 12, x) # column 1
		quarter_round(5, 9, 13, 1, x) # column 2
		quarter_round(10, 14, 2, 6, x) # column 3
		quarter_round(15, 3, 7, 11, x) # column 4
		# Even round
		quarter_round(0, 1, 2, 3, x) # row 1
		quarter_round(5, 6, 7, 4, x) # row 2
		quarter_round(10, 11, 8, 9, x) # row 3
		quarter_round(15, 12, 13, 14, x) # row 4
	var output = []
	for i in 16:
		output.append((x[i] + state[i]) & mask)
	state = output
	return output


func get_bytes_from_words(words):
	var bytes = []
	for word in words:
		for i in 4:
			bytes.append(word % 256)
			word /= 256
	return bytes


func get_word_from_bytes(bytes: PoolByteArray):
	# Convert 4 bytes to a 32 bit word in little endian format
	bytes.invert()
	var word = 0
	for n in bytes.size():
		word *= 256
		word += bytes[n]
	return word


func rotate_left_32(word, n):
	return ( ( ( word << n ) & mask) | ( word >> ( 32 - n ) ) )


func quarter_round(a, b, c, d, x):
	x[b] ^= rotate_left_32((x[a] + x[d]) & mask, 7)
	x[c] ^= rotate_left_32((x[b] + x[a]) & mask, 9)
	x[d] ^= rotate_left_32((x[c] + x[b]) & mask, 13)
	x[a] ^= rotate_left_32((x[d] + x[c]) & mask, 18)
