extends GutTest

var settings = Settings.new()

func test_get_char():
	for n in 10:
		assert_eq(settings.get_char(n), str(n))
	assert_eq(settings.get_char(10), "a")
	assert_eq(settings.get_char(35), "z")

func test_generate_salt():
	# Short user-friendly
	for n in 10:
		var salt = settings.generate_salt(true)
		if n == 0:
			assert_typeof(salt, TYPE_STRING)
		assert_true(salt.length() < 13, "Length <= 12")
		assert_true(salt.length() > 7, "Length >= 8")
	# Long computer only
	var salt = settings.generate_salt(false)
	assert_true(salt.length() > 20, "Length > 20")
	assert_ne(salt, "long salt")
