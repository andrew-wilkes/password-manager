extends GutTest

var settings = Settings.new()

func test_get_char():
	for n in 10:
		assert_eq(settings.get_char(n), str(n))

func test_generate_salt():
	for n in 10:
		var salt = settings.generate_salt()
		if n == 0:
			assert_typeof(salt, TYPE_STRING)
		assert_true(salt.length() < 13, "Length <= 12")
		assert_true(salt.length() > 7, "Length >= 8")
