extends GutTest

func test_increment_filename():
	var fname = "xyz.pwd"
	fname = Utility.increment_filename(fname)
	assert_eq(fname, "xyz1.pwd")
	fname = Utility.increment_filename(fname)
	assert_eq(fname, "xyz2.pwd")
	fname = "1xyz.pwd"
	fname = Utility.increment_filename(fname)
	assert_eq(fname, "1xyz1.pwd")
	fname = "xy1z.pwd"
	fname = Utility.increment_filename(fname)
	assert_eq(fname, "xy1z1.pwd")
	fname = "xyz123.pwd"
	fname = Utility.increment_filename(fname)
	assert_eq(fname, "xyz124.pwd")
