extends Node

class_name TimeEstimates
# from decimal import Decimal, Context, Inexact

static func estimate_attack_times(guesses):
	var crack_times_seconds = {
		'online_throttling_100_per_hour': Scoring.Decimal(guesses) / float_to_decimal(100.0 / 3600.0),
		'online_no_throttling_10_per_second': Scoring.Decimal(guesses) / float_to_decimal(10.0),
		'offline_slow_hashing_1e4_per_second': Scoring.Decimal(guesses) / float_to_decimal(1e4),
		'offline_fast_hashing_1e10_per_second': Scoring.Decimal(guesses) / float_to_decimal(1e10),
	}

	var crack_times_display = {}
	for scenario in crack_times_seconds.keys():
		crack_times_display[scenario] = display_time(crack_times_seconds[scenario])

	return {
		'crack_times_seconds': crack_times_seconds,
		'crack_times_display': crack_times_display,
		'score': guesses_to_score(guesses),
	}


static func guesses_to_score(guesses):
	var delta = 5

	if guesses < 1e3 + delta:
		# risky password: "too guessable"
		return 0
	elif guesses < 1e6 + delta:
		# modest protection from throttled online attacks: "very guessable"
		return 1
	elif guesses < 1e8 + delta:
		# modest protection from unthrottled online attacks: "somewhat
		# guessable"
		return 2
	elif guesses < 1e10 + delta:
		# modest protection from offline attacks: "safely unguessable"
		# assuming a salted, slow hash function like bcrypt, scrypt, PBKDF2,
		# argon, etc
		return 3
	else:
		# strong protection from offline attacks under same scenario: "very
		# unguessable"
		return 4


static func display_time(seconds):
	var minute = 60
	var hour = minute * 60
	var day = hour * 24
	var month = day * 31
	var year = month * 12
	var century = year * 100
	var display_num
	var display_str
	var base
	if seconds < 1:
		display_str = 'less than a second'
	elif seconds < minute:
		base = round(seconds)
		display_num = base
		display_str = '%s second' % base
	elif seconds < hour:
		base = round(seconds / minute)
		display_num = base
		display_str = '%s minute' % base
	elif seconds < day:
		base = round(seconds / hour)
		display_num = base
		display_str = '%s hour' % base
	elif seconds < month:
		base = round(seconds / day)
		display_num =base
		display_str = '%s day' % base
	elif seconds < year:
		base = round(seconds / month)
		display_num = base
		display_str = '%s month' % base
	elif seconds < century:
		base = round(seconds / year)
		display_num = base
		display_str = '%s year' % base
	else:
		display_str = 'centuries'

	if display_num and display_num != 1:
		display_str += 's'

	return display_str


static func float_to_decimal(f):
	return f
	"""
	# Convert a floating point number to a Decimal with no loss of information
	n, d = f.as_integer_ratio()
	numerator, denominator = Decimal(n), Decimal(d)
	ctx = Context(prec=60)
	result = ctx.divide(numerator, denominator)
	while ctx.flags[Inexact]:
		ctx.flags[Inexact] = False
		ctx.prec *= 2
		result = ctx.divide(numerator, denominator)
	return result
	"""
