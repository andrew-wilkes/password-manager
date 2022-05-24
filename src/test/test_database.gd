extends GutTest

func test_order_items_ascending():
	var db = Database.new()
	db.items = [{ "prop": "a" }, { "prop": "d" }, { "prop": "c" }, { "prop": "b" }]
	db.order_items("prop", false)
	assert_eq(db.items[0].prop, "a")
	assert_eq(db.items[1].prop, "b")
	assert_eq(db.items[2].prop, "c")
	assert_eq(db.items[3].prop, "d")

func test_order_items_descending():
	var db = Database.new()
	db.items = [{ "prop": "a" }, { "prop": "d" }, { "prop": "c" }, { "prop": "b" }]
	db.order_items("prop", true)
	assert_eq(db.items[0].prop, "d")
	assert_eq(db.items[1].prop, "c")
	assert_eq(db.items[2].prop, "b")
	assert_eq(db.items[3].prop, "a")
