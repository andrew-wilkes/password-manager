extends Node

const L33T_TABLE = {
	'a': ['4', '@'],
	'b': ['8'],
	'c': ['(', '{', '[', '<'],
	'e': ['3'],
	'g': ['6', '9'],
	'i': ['1', '!', '|'],
	'l': ['1', '|', '7'],
	'o': ['0'],
	's': ['$', '5'],
	't': ['+', '7'],
	'x': ['%'],
	'z': ['2'],
}

const DATE_MAX_YEAR = 2050
const DATE_MIN_YEAR = 1000
const DATE_SPLITS = {
	4: [  # for length-4 strings, eg 1191 or 9111, two ways to split:
		[1, 2],  # 1 1 91 (2nd split starts at index 1, 3rd at index 2)
		[2, 3],  # 91 1 1
	],
	5: [
		[1, 3],  # 1 11 91
		[2, 3],  # 11 1 91
	],
	6: [
		[1, 2],  # 1 1 1991
		[2, 4],  # 11 11 91
		[4, 5],  # 1991 1 1
	],
	7: [
		[1, 3],  # 1 11 1991
		[2, 3],  # 11 1 1991
		[4, 5],  # 1991 1 11
		[4, 6],  # 1991 11 1
	],
	8: [
		[2, 4],  # 11 11 1991
		[4, 6],  # 1991 11 11
	],
}

const REGEXEN = {
	'recent_year': '19\\d\\d|20\\d\\d'
}

const SHIFTED_RX = '[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]'
const MAX_DELTA = 5

var RANKED_DICTIONARIES = {}

var GRAPHS = {
	'qwerty': AdjacencyGraphs.data['qwerty'],
	'dvorak': AdjacencyGraphs.data['dvorak'],
	'keypad': AdjacencyGraphs.data['keypad'],
	'mac_keypad': AdjacencyGraphs.data['mac_keypad'],
}

class MatchSorter:
	static func sort_by_ij(ma, mb):
		if ma['i'] < mb['i']: return true
		if ma['i'] > mb['i']: return false
		if ma['j'] > mb['j']: return false
		return true

func _init():
	add_frequency_lists(FrequencyLists.data)


func add_frequency_lists(frequency_lists):
	for name in frequency_lists.data.keys():
		RANKED_DICTIONARIES[name] = build_ranked_dict(frequency_lists.data[name])


func build_ranked_dict(ordered_list):
	var dict = {}
	var n = 1
	for word in ordered_list:
		dict[word] = n
		n += 1
	return dict


# omnimatch -- perform all matches
func omnimatch(password, _ranked_dictionaries=RANKED_DICTIONARIES):
	var matches = []
	var args = [password, _ranked_dictionaries]
	for matcher in [
		"dictionary_match",
		"reverse_dictionary_match",
		"l33t_match",
		"spatial_match",
		"repeat_match",
		"sequence_match",
		"regex_match",
		"date_match",
	]:
		matches.append(callv(matcher, args))

	return matches.sort_custom(MatchSorter, "sort_by_ij")


# dictionary match (common passwords, english, last names, etc)
func dictionary_match(password, _ranked_dictionaries=RANKED_DICTIONARIES):
	var matches = []
	var length = len(password)
	var password_lower = password.to_lower()
	for dictionary_name in _ranked_dictionaries.keys():
		var ranked_dict = _ranked_dictionaries[dictionary_name]
		for i in range(length):
			for j in range(i, length):
				var word = password_lower.substr(i, j + 1)
				if word in ranked_dict:
					var rank = ranked_dict[word]
					matches.append({
						'pattern': 'dictionary',
						'i': i,
						'j': j,
						'token': password.substr(i, j + 1),
						'matched_word': word,
						'rank': rank,
						'dictionary_name': dictionary_name,
						'reversed': false,
						'l33t': false,
					})

	return matches.sort_custom(MatchSorter, "sort_by_ij")


func reverse_dictionary_match(password: String, _ranked_dictionaries = RANKED_DICTIONARIES):
	var reversed_password = reverse_string(password)
	var matches = dictionary_match(reversed_password, _ranked_dictionaries)
	for _match in matches:
		_match['token'] = reverse_string(_match['token'])
		_match['reversed'] = true
		_match['i'] = len(password) - 1 - _match['j']
		_match['j'] = len(password) - 1 - _match['i']

	return matches.sort_custom(MatchSorter, "sort_by_ij")


func reverse_string(s):
	return s.split("").invert().join("")


func l33t_match(password, _ranked_dictionaries=RANKED_DICTIONARIES,
			   _l33t_table=L33T_TABLE):
	var matches = []

	for sub in enumerate_l33t_subs(relevant_l33t_subtable(password, _l33t_table)):
		if len(sub) < 1:
			break

		var subbed_password = translate(password, sub)
		for _match in dictionary_match(subbed_password, _ranked_dictionaries):
			var token = password.substr(_match['i'], _match['j'] - _match['i'] + 1)
			if token.to_lower() == _match['matched_word']:
				# only return the matches that contain an actual substitution
				continue

			# subset of mappings in sub that are in use for this match
			var match_sub = {}
			for subbed_chr in sub.keys():
				if subbed_chr in token:
					match_sub[subbed_chr] = sub[subbed_chr]
			_match['l33t'] = true
			_match['token'] = token
			_match['sub'] = match_sub
			var subs = PoolStringArray()
			for k in match_sub.keys():
				subs.append("%s -> %s" % [k, match_sub[k]])
			_match['sub_display'] = subs.join(', ')
			matches.append(_match)
	var _matches = []
	for _match in matches:
		if len(_match['token']) > 1:
			_matches.append(_match)

	return _matches.sort_custom(MatchSorter, "sort_by_ij")


func relevant_l33t_subtable(password, table):
	var password_chars = {}
	for ch in password:
		password_chars[ch] = true

	var subtable = {}
	var relevant_subs = []
	for letter in table.keys():
		for sub in table[letter]:
			if sub in password_chars:
				relevant_subs.append(sub)
		if len(relevant_subs) > 0:
			subtable[letter] = relevant_subs

	return subtable


func translate(string, chr_map):
	var chars = PoolStringArray()
	for ch in string:
		if chr_map.has(ch):
			chars.append(chr_map[ch])
		else:
			chars.append(ch)

	return chars.join("")


func enumerate_l33t_subs(table):
	var keys = table.keys()
	var subs = [[]]
	subs = helper(keys, subs, table)
	var sub_dicts = []  # convert from assoc lists to dicts
	for sub in subs:
		var sub_dict = {}
		for pair in sub:
			sub_dict[pair[0]] = pair[1]
		sub_dicts.append(sub_dict)

	return sub_dicts


func helper(keys, subs, table):
	if len(keys) < 1:
		return subs

	var first_key = keys[0]
	var rest_keys = keys.slice(1, -1)
	var next_subs = []
	for l33t_chr in table[first_key]:
		for sub in subs:
			var dup_l33t_index = -1
			for i in range(len(sub)):
				if sub[i][0] == l33t_chr:
					dup_l33t_index = i
					break
			if dup_l33t_index == -1:
				var sub_extension = sub
				sub_extension.append([l33t_chr, first_key])
				next_subs.append(sub_extension)
			else:
				var sub_alternative = sub
				sub_alternative.pop(dup_l33t_index)
				sub_alternative.append([l33t_chr, first_key])
				next_subs.append(sub)
				next_subs.append(sub_alternative)

	subs = dedup(next_subs)
	return helper(rest_keys, subs, table)


func dedup(subs):
	var deduped = []
	var members = {}
	for sub in subs:
		var assoc = []
		for k in sub.keys():
			assoc.append(sub[k] + "," + k)
		assoc.sort()
		var label = PoolStringArray(assoc).join("-")
		if not label in members:
			members[label] = true
			deduped.append(sub)

	return deduped


# repeats (aaa, abcabcabc) and sequences (abcdef)
func repeat_match(password, _ranked_dictionaries=RANKED_DICTIONARIES):
	var matches = []
	var greedy = RegEx.new()
	greedy.compile('(.+)\\1+')
	var lazy = RegEx.new()
	lazy.compile('(.+?)\\1+')
	var lazy_anchored = RegEx.new()
	lazy_anchored.compile('^(.+?)\\1+$')
	var last_index = 0
	while last_index < len(password):
		var greedy_match = greedy.search(password, last_index)
		var lazy_match = lazy.search(password, last_index)

		if not greedy_match:
			break

		var _match
		var base_token
		if len(greedy_match.get_string()) > len(lazy_match.get_string()):
			# greedy beats lazy for 'aabaab'
			#   greedy: [aabaab, aab]
			#   lazy:   [aa,     a]
			_match = greedy_match
			# greedy's repeated string might itself be repeated, eg.
			# aabaab in aabaabaabaab.
			# run an anchored lazy match on greedy's repeated string
			# to find the shortest repeated string
			base_token = lazy_anchored.search(_match.get_string()).get_string(1)
		else:
			_match = lazy_match
			base_token = _match.get_string()

		var i = _match.get_start()
		var j = _match.get_end()

		# recursively match and score the base string
		var base_analysis = Scoring.most_guessable_match_sequence(
			base_token,
			omnimatch(base_token)
		)
		var base_matches = base_analysis['sequence']
		var base_guesses = base_analysis['guesses']
		matches.append({
			'pattern': 'repeat',
			'i': i,
			'j': j,
			'token': _match.get_string(),
			'base_token': base_token,
			'base_guesses': base_guesses,
			'base_matches': base_matches,
			'repeat_count': len(_match.get_string()) / len(base_token),
		})
		last_index = j + 1

	return matches


func spatial_match(password, _graphs=GRAPHS, _ranked_dictionaries=RANKED_DICTIONARIES):
	var matches = []
	for graph_name in _graphs.keys():
		matches.append_array(spatial_match_helper(password, _graphs[graph_name], graph_name))

	return matches.sort_custom(MatchSorter, "sort_by_ij")


func spatial_match_helper(password, graph, graph_name):
	var matches = []
	var i = 0
	var shifted_rx = RegEx.new()
	shifted_rx.compile(SHIFTED_RX)
	while i < len(password) - 1:
		var j = i + 1
		var last_direction = null
		var turns = 0
		var shifted_count = 0
		if graph_name in ['qwerty', 'dvorak', ] and shifted_rx.search(password[i]):
			# initial character is shifted
			shifted_count = 1

		while true:
			var prev_char = password[j - 1]
			var found = false
			var found_direction = -1
			var cur_direction = -1
			var adjacents = []
			if graph.has(prev_char):
				adjacents = graph[prev_char]
				
			# consider growing pattern by one character if j hasn't gone over the edge.
			if j < len(password):
				var cur_char = password[j]
				for adj in adjacents:
					cur_direction += 1
					if adj and cur_char in adj:
						found = true
						found_direction = cur_direction
						if adj.find(cur_char) == 1:
							# index 1 in the adjacency means the key is shifted,
							# 0 means unshifted: A vs a, % vs 5, etc.
							# for example, 'q' is adjacent to the entry '2@'.
							# @ is shifted w/ index 1, 2 is unshifted.
							shifted_count += 1
						if last_direction != found_direction:
							# adding a turn is correct even in the initial case
							# when last_direction is null:
							# every spatial pattern starts with a turn.
							turns += 1
							last_direction = found_direction
						break
			# if the current pattern continued, extend j and try to grow again
			if found:
				j += 1
			# otherwise push the pattern discovered so far, if any...
			else:
				if j - i > 2:  # don't consider length 1 or 2 chains.
					matches.append({
						'pattern': 'spatial',
						'i': i,
						'j': j - 1,
						'token': password.substr(i, j - i + 1),
						'graph': graph_name,
						'turns': turns,
						'shifted_count': shifted_count,
					})
				# ...and then start a new search for the rest of the password.
				i = j
				break

	return matches


func sequence_match(password, _ranked_dictionaries=RANKED_DICTIONARIES):
	# Identifies sequences by looking for repeated differences in unicode codepoint.
	# this allows skipping, such as 9753, and also matches some extended unicode sequences
	# such as Greek and Cyrillic alphabets.
	#
	# for example, consider the input 'abcdb975zy'
	#
	# password: a   b   c   d   b    9   7   5   z   y
	# index:    0   1   2   3   4    5   6   7   8   9
	# delta:      1   1   1  -2  -41  -2  -2  69   1
	#
	# expected result:
	# [(i, j, delta), ...] = [(0, 3, 1), (5, 7, -2), (8, 9, 1)]
	if len(password) == 1:
		return []

	var result = []
	var i = 0
	var last_delta = null

	for k in range(1, len(password)):
		var delta = ord(password[k]) - ord(password[k - 1])
		if last_delta == null:
			last_delta = delta
		if delta == last_delta:
			continue
		var j = k - 1
		update(i, j, last_delta, password, result)
		i = j
		last_delta = delta
	update(i, len(password) - 1, last_delta, password, result)

	return result

func update(i, j, delta, password, result):
	if j - i > 1 or (delta and abs(delta) == 1):
		if 0 < abs(delta) and abs(delta) <= MAX_DELTA:
			var token = password.substr(i, j - i + 1)
			var regex = RegEx.new()
			var sequence_name
			var sequence_space
			if regex.compile('^[a-z]+$').search(token):
				sequence_name = 'lower'
				sequence_space = 26
			elif regex.compile('^[A-Z]+$').search(token):
				sequence_name = 'upper'
				sequence_space = 26
			elif regex.compile('^\\d+$').search(token):
				sequence_name = 'digits'
				sequence_space = 10
			else:
				sequence_name = 'unicode'
				sequence_space = 26
			result.append({
				'pattern': 'sequence',
				'i': i,
				'j': j,
				'token': token,
				'sequence_name': sequence_name,
				'sequence_space': sequence_space,
				'ascending': delta > 0
			})
	return result


func regex_match(password, _regexen=REGEXEN, _ranked_dictionaries=RANKED_DICTIONARIES):
	var matches = []
	var regex = RegEx.new()
	for name in _regexen.keys():
		regex.compile(_regexen[name])
		for rx_match in regex.search_all(password):
			matches.append({
				'pattern': 'regex',
				'token': rx_match.get_string(),
				'i': rx_match.start(),
				'j': rx_match.end(),
				'regex_name': name,
				'regex_match': rx_match,
			})

	return matches.sort_custom(MatchSorter, "sort_by_ij")


func date_match(password, _ranked_dictionaries=RANKED_DICTIONARIES):
	# a "date" is recognized as:
	#   any 3-tuple that starts or ends with a 2- or 4-digit year,
	#   with 2 or 0 separator chars (1.1.91 or 1191),
	#   maybe zero-padded (01-01-91 vs 1-1-91),
	#   a month between 1 and 12,
	#   a day between 1 and 31.
	#
	# note: this isn't true date parsing in that "feb 31st" is allowed,
	# this doesn't check for leap years, etc.
	#
	# recipe:
	# start with regex to find maybe-dates, then attempt to map the integers
	# onto month-day-year to filter the maybe-dates into dates.
	# finally, remove matches that are substrings of other matches to reduce noise.
	#
	# note: instead of using a lazy or greedy regex to find many dates over the full string,
	# this uses a ^...$ regex against every substring of the password -- less performant but leads
	# to every possible date match.
	var matches = []
	var maybe_date_no_separator = RegEx.new()
	maybe_date_no_separator.compile('^\\d{4,8}$')
	var maybe_date_with_separator = RegEx.new()
	maybe_date_with_separator.compile(
		'^(\\d{1,4})([\\s/\\_.-])(\\d{1,2})\\2(\\d{1,4})$'
	)

	# dates without separators are between length 4 '1191' and 8 '11111991'
	for i in range(len(password) - 3):
		for j in range(i + 3, i + 8):
			if j >= len(password):
				break

			var token = password.substr(i, j - i + 1)
			if not maybe_date_no_separator.search(token):
				continue
			var candidates = []
			var ds = DATE_SPLITS[len(token)]
			for splits in ds.keys:
				var dmy = map_ints_to_dmy([
					int(token.substr(0, splits[0])),
					int(token.substr(splits[0], splits[1] - splits[0])),
					int(token.substr(splits[1]))
				])
				if dmy:
					candidates.append(dmy)
			if not len(candidates) > 0:
				continue
			# at this point: different possible dmy mappings for the same i,j
			# substring. match the candidate date that likely takes the fewest
			# guesses: a year closest to 2000. (scoring.REFERENCE_YEAR).
			#
			# ie, considering '111504', prefer 11-15-04 to 1-1-1504
			# (interpreting '04' as 2004)
			var best_candidate = candidates[0]
			
			var min_distance = metric(candidates[0])
			for candidate in candidates.slice(1, -1):
				var distance = metric(candidate)
				if distance < min_distance:
					best_candidate = candidate
					min_distance = distance
			matches.append({
				'pattern': 'date',
				'token': token,
				'i': i,
				'j': j,
				'separator': '',
				'year': best_candidate['year'],
				'month': best_candidate['month'],
				'day': best_candidate['day'],
			})

	# dates with separators are between length 6 '1/1/91' and 10 '11/11/1991'
	for i in range(len(password) - 5):
		for j in range(i + 5, i + 10):
			if j >= len(password):
				break
			var token = password.substr(i, j - i + 1)
			var rx_match = maybe_date_with_separator.search(token)
			if not rx_match:
				continue
			var dmy = map_ints_to_dmy([
				int(rx_match.get_string(1)),
				int(rx_match.get_string(3)),
				int(rx_match.get_string(4)),
			])
			if not dmy:
				continue
			matches.append({
				'pattern': 'date',
				'token': token,
				'i': i,
				'j': j,
				'separator': rx_match.get_string(2),
				'year': dmy['year'],
				'month': dmy['month'],
				'day': dmy['day'],
			})
	# matches now contains all valid date strings in a way that is tricky to
	# capture with regexes only. while thorough, it will contain some
	# unintuitive noise:
	#
	# '2015_06_04', in addition to matching 2015_06_04, will also contain
	# 5(!) other date matches: 15_06_04, 5_06_04, ..., even 2015
	# (matched as 5/1/2020)
	#
	# to reduce noise, remove date matches that are strict substrings of others
	var _matches = []
	for _match in matches:
		if filter_fun(_match, matches):
			_matches.append(_match)
	
	return _matches.sort_custom(MatchSorter, "sort_by_ij")


func metric(candidate_):
	return abs(candidate_['year'] - Scoring.REFERENCE_YEAR)


func filter_fun(_match, matches):
	var is_submatch = false
	for other in matches:
		if _match == other:
			continue
		if other['i'] <= _match['i'] and other['j'] >= _match['j']:
			is_submatch = true
			break
	return not is_submatch


func map_ints_to_dmy(ints):
	# given a 3-tuple, discard if:
	#   middle int is over 31 (for all dmy formats, years are never allowed in
	#   the middle)
	#   middle int is zero
	#   any int is over the max allowable year
	#   any int is over two digits but under the min allowable year
	#   2 ints are over 31, the max allowable day
	#   2 ints are zero
	#   all ints are over 12, the max allowable month
	if ints[1] > 31 or ints[1] <= 0:
		return
	var over_12 = 0
	var over_31 = 0
	var under_1 = 0
	for i in ints:
		if 99 < i and i < DATE_MIN_YEAR or i > DATE_MAX_YEAR:
			return
		if i > 31:
			over_31 += 1
		if i > 12:
			over_12 += 1
		if i <= 0:
			under_1 += 1
	if over_31 >= 2 or over_12 == 3 or under_1 >= 2:
		return

	# first look for a four digit year: yyyy + daymonth or daymonth + yyyy
	var possible_four_digit_splits = [
		[ints[2], [ints[0], ints[1]]],
		[ints[0], [ints[1], ints[2]]],
	]
	for date in possible_four_digit_splits:
		if DATE_MIN_YEAR <= date[0] and date[0] <= DATE_MAX_YEAR:
			var dm = map_ints_to_dm(date[1])
			if dm:
				return {
					'year': date[0],
					'month': dm['month'],
					'day': dm['day'],
				}
			else:
				# for a candidate that includes a four-digit year,
				# when the remaining ints don't match to a day and month,
				# it is not a date.
				return

	# given no four-digit year, two digit years are the most flexible int to
	# match, so try to parse a day-month out of ints[0..1] or ints[1..0]
	for date in possible_four_digit_splits:
		var dm = map_ints_to_dm(date[1])
		if dm:
			return {
				'year': two_to_four_digit_year(date[0]),
				'month': dm['month'],
				'day': dm['day'],
			}


func map_ints_to_dm(ints):
	var d = ints[0]
	var m = ints[1]
	if 1 <= d and d <= 31 and 1 <= m and m <= 12:
		return {
			'day': d,
			'month': m,
		}
	d = m
	m = ints[0]
	if 1 <= d and d <= 31 and 1 <= m and m <= 12:
		return {
			'day': d,
			'month': m,
		}


func two_to_four_digit_year(year):
	if year > 99:
		return year
	elif year > 50:
		# 87 -> 1987
		return year + 1900
	else:
		# 15 -> 2015
		return year + 2000
