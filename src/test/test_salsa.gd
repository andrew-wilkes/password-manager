extends GutTest

var key = range(1,33)
var iv = [3,1,4,1,5,9,2,6]
var state = [ 0xb9a205a3,0x0695e150,0xaa94881a,0xadb7b12c,
	   0x798942d4,0x26107016,0x64edb1a4,0x2d27173f,
	   0xb1c7f1fa,0x62066edc,0xe035fa23,0xc4496f04,
	   0x2131e6b3,0x810bde28,0xf62cb407,0x6bdede3d ]

func test_salsa():
	var salsa = Salsa20.new(key, iv, [7, 0])
	assert_eq(salsa.salsa20_block(), state)


func test_get_bytes_from_words():
	var salsa = Salsa20.new(key, iv)
	var words = [67305985]
	assert_eq(salsa.get_bytes_from_words(words), [1,2,3,4])
