extends WindowDialog

signal date_changed(new_date)

export(Color) var light_color = Color(1.0, 1.0, 1.0)
export(Color) var dark_color = Color(0.5, 0.5, 0.5)

var current_date
var original_date
var current_month_idx_start
var current_month_idx_end

func _ready():
	for n in 41:
		$VB/Grid.add_child($VB/Grid/Day1.duplicate())
	for idx in range(7, 49):
		var _e = $VB/Grid.get_child(idx).connect("pressed", self, "_on_day_button_pressed", [$VB/Grid.get_child(idx), idx])
	if get_parent().name == "root":
		open(OS.get_date(), window_title + " TEST")


func set_panel_size():
	yield(get_tree(), "idle_frame")
	rect_size = $VB.rect_size


func open(date, title = ""):
	if not title.empty():
		window_title = title
	original_date = date
	current_date = date
	set_date(date)
	set_digits(date)
	yield(get_tree(), "idle_frame")
	popup_centered()
	#call_deferred("set_panel_size")


func set_date(date):
	$VB/Day.text = Date.WEEKDAY_NAME[Date.get_weekday(date["day"], date["month"], date["year"])]
	var month = Date.MONTH_NAME[date["month"] - 1]
	var year = str(date["year"])
	$VB/Date.text = month + " " + str(date["day"]) + ", " + year
	$VB/Navigation/Month.text = month
	$VB/Navigation/Year.text = year


func set_digits(date):
	var idx = 7
	var start_day_of_month = Date.get_weekday(0, date["month"], date["year"])
	var days_in_month = Date.get_days_in_month(date["month"], date["year"])
	# Add days ending last month
	if start_day_of_month != 6: # Sunday
		var last_months_year = date["year"]
		var last_month = date["month"] - 1
		if last_month == 0:
			last_month = 12
			last_months_year -= 1
		var days_in_month_before = Date.get_days_in_month(last_month, last_months_year)
		var day_number = days_in_month_before - start_day_of_month
		for n in start_day_of_month + 1:
			set_digit(day_number, dark_color, idx)
			idx += 1
			day_number += 1
	current_month_idx_start = idx
	for n in days_in_month:
		set_digit(n + 1, light_color, idx)
		if n + 1 == date["day"]:
			$VB/Grid.get_child(idx).pressed = true
		idx += 1
	current_month_idx_end = idx - 1
	var day_number = 1
	while idx < 49:
		set_digit(day_number, dark_color, idx)
		idx += 1
		day_number += 1


func set_digit(value, color, idx):
	$VB/Grid.get_child(idx).text = str(value)
	$VB/Grid.get_child(idx).set("custom_colors/font_color", color)


func _on_MonthLeft_pressed():
	go_back_a_month()


func go_back_a_month():
	current_date["month"] = wrapi(current_date["month"] - 1, 1, 13)
	set_date(current_date)
	set_digits(current_date)


func _on_MonthRight_pressed():
	go_forward_a_month()


func go_forward_a_month():
	current_date["month"] = wrapi(current_date["month"] + 1, 1, 13)
	set_date(current_date)
	set_digits(current_date)


func _on_YearLeft_pressed():
	current_date["year"] -= 1
	set_date(current_date)
	set_digits(current_date)


func _on_YearRight_pressed():
	current_date["year"] += 1
	set_date(current_date)
	set_digits(current_date)


func _on_day_button_pressed(button, idx):
	current_date["day"] = int(button.text)
	var reset_digits = false
	if idx < current_month_idx_start:
		go_back_a_month()
		reset_digits = true
	if idx > current_month_idx_end:
		go_forward_a_month()
		reset_digits = true
	set_date(current_date)
	if reset_digits:
		set_digits(current_date)


func _on_DatePicker_popup_hide():
	if current_date != original_date:
		emit_signal("date_changed", current_date)
