extends GutTest

func test_record():
	var record = Record.new()
	assert_true(record.data.has("password"))
