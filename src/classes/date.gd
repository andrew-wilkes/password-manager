class_name Date

enum Month { JAN = 1, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC }

const MONTH_NAME = [ 
		"Jan", "Feb", "Mar", "Apr", 
		"May", "Jun", "Jul", "Aug", 
		"Sep", "Oct", "Nov", "Dec" ]

const WEEKDAY_NAME = [ 
		"Sunday", "Monday", "Tuesday", "Wednesday", 
		"Thursday", "Friday", "Saturday" ]

# Supported Date Formats:
# DD : Two digit day of month
# MM : Two digit month
# YY : Two digit year
# YYYY : Four digit year
static func format(date, date_format = "DD-MM-YY"):
	if("DD".is_subsequence_of(date_format)):
		date_format = date_format.replace("DD", "%02d" % date["day"])
	if("MM".is_subsequence_of(date_format)):
		date_format = date_format.replace("MM", "%02d" % date["month"])
	if("YYYY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YYYY", str(date["year"]))
	elif("YY".is_subsequence_of(date_format)):
		date_format = date_format.replace("YY", str(date["year"]).substr(2,3))
	return date_format


static func get_days_in_month(month : int, year : int) -> int:
	var number_of_days : int
	if(month == Month.APR || month == Month.JUN || month == Month.SEP || month == Month.NOV):
		number_of_days = 30
	elif(month == Month.FEB):
		var is_leap_year = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
		if(is_leap_year):
			number_of_days = 29
		else:
			number_of_days = 28
	else:
		number_of_days = 31
	
	return number_of_days


static func get_weekday(day : int, month : int, year : int) -> int:
	var t : Array = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	if(month < 3):
		year -= 1
	return int(year + year/4.0 - year/100.0 + year/400.0 + t[month - 1] + day) % 7


static func get_weekday_name(day : int, month : int, year : int):
	var day_num = get_weekday(day, month, year)
	return WEEKDAY_NAME[day_num]


static func get_month_name(month : int):
	return MONTH_NAME[month - 1]
