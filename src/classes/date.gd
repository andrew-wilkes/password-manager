class_name Date

enum Month { JAN = 1, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC }

const MONTH_NAME = [ 
		"January", "February", "March", "April", 
		"May", "June", "July", "August", 
		"September", "October", "November", "December" ]

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


static func sanitize_date_format(txt: String):
	# Allow the user great flexibility in how they mix up dashes and YMD
	var date = ""
	txt = txt.lstrip("-")
	txt = txt.rstrip("-")
	var counts = {
		"?": 0,
		"-": 0,
		"Y": 0,
		"M": 0,
		"D": 0,
	}
	var last_chr = "?" # Dummy chr
	# Make the loop do one extra pass to catch say YYY
	txt += last_chr
	for chr in txt:
		if chr == last_chr:
			# No more than one dash inline
			if last_chr == "-":
				continue
			# Ensure that there are 2 or 4 chrs
			if chr == "Y" and counts[chr] < 4 or counts[chr] < 2:
				date += chr
				counts[chr] += 1
		else:
			if last_chr != "-":
				# chr changed so fix length of preceeding chr sequence
				if counts[last_chr] == 1 or counts[last_chr] == 3:
					date += last_chr
					# Don't allow any more of last_chr
					counts[last_chr] = 4
			# Up to 2 separated dashes are allowed
			if chr == "-" and counts[chr] < 2:
					date += chr
					counts[chr] += 1
			else:
				# Can accept a new starting chr
				if counts[chr] == 0:
					date += chr
					counts[chr] = 1
		last_chr = chr
	return date.rstrip("?-")


static func get_unix_time_from_iso_string(iso: String):
	# Only care about the date
	var ymd = iso.split("T")[0].split("-")
	var date = {}
	for idx in ymd.size():
		match idx:
			0:
				date["year"] = int(ymd[0])
			1:
				date["month"] = int(ymd[1])
			2:
				date["day"] = int(ymd[2])
	return OS.get_unix_time_from_datetime(date)
