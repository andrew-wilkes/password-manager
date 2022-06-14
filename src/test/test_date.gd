extends GutTest

func test_format():
	var date = OS.get_date()
	var formatted_date = Date.format(date)
	assert_eq(formatted_date.length(), 8)
	formatted_date = Date.format(date, "YYYY-MM-DD")
	assert_eq(formatted_date.length(), 10)
	assert_true(formatted_date.begins_with(str(date["year"]) + "-"))

func test_get_days_in_month():
	var dim = Date.get_days_in_month(5, 2022)
	assert_eq(dim, 31)
	dim = Date.get_days_in_month(2, 2022)
	assert_eq(dim, 28)

func test_get_weekday():
	var day = Date.get_weekday(19, 8, 2027)
	assert_eq(day, 4)

func test_get_weekday_name():
	var day = Date.get_weekday_name(20, 8, 2027)
	assert_eq(day, "Friday")

func test_get_month_name():
	var month = Date.get_month_name(12)
	assert_eq(month, "December")

func test_sanitize_date_format():
	var date = Date.sanitize_date_format("MM-DD-YYYY")
	assert_eq(date, "MM-DD-YYYY")
	date = Date.sanitize_date_format("M--DDD-YYY")
	assert_eq(date, "MM-DD-YYYY")
	date = Date.sanitize_date_format("-YMD-")
	assert_eq(date, "YYMMDD")
	date = Date.sanitize_date_format("YY-MMDD-Y")
	assert_eq(date, "YY-MMDD")
