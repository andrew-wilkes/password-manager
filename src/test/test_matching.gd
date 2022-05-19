extends GutTest

# takes a pattern and list of prefixes/suffixes
# returns a bunch of variants of that pattern embedded
# with each possible prefix/suffix combination, including no prefix/suffix
# returns a list of triplets [variant, i, j] where [i,j] is the start/end of the
# pattern, inclusive
func genpws(pattern, prefixes, suffixes):
	for lst in [prefixes, suffixes]:
		if not '' in lst:
			lst.push_front('')
	var result = []
	for prefix in prefixes:
		for suffix in suffixes:
			var i = len(prefix)
			var j = len(prefix) + len(pattern) - 1
			result.append([prefix + pattern + suffix, i, j])
	return result

func check_matches(prefix, matches, pattern_names, patterns, ijs, props):
	if pattern_names is String:
		# shortcut: if checking for a list of the same type of patterns,
		# allow passing a string 'pat' instead of array ['pat', 'pat', ...]
		var pname = pattern_names
		pattern_names = []
		for _n in len(patterns):
			pattern_names.append(pname)

	var is_equal_len_args = pattern_names.size() == patterns.size() and patterns.size() == ijs.size()
	for lst in props:
		# props is structured as: keys that points to list of values
		if not is_equal_len_args or props[lst].size() != patterns.size():
			fail_test('unequal argument lists to check_matches')

	var msg = "%s: len(matches) == %s" % [prefix, patterns.size()]
	assert_true(matches.size() == patterns.size(), msg)
	if matches.size() != patterns.size():
		return
	for k in range(patterns.size()):
		var _match = matches[k]
		var pattern_name = pattern_names[k]
		var pattern = patterns[k]
		var i = ijs[k][0]
		var j = ijs[k][1]
		msg = "%s: matches[%s]['pattern'] == '%s'" % [prefix, k, pattern_name]
		assert_true(_match['pattern'] == pattern_name, msg)

		msg = "%s: matches[%s] should have [i, j] of [%s, %s]" % [prefix, k, i, j]
		assert_true([_match['i'], _match['j']] == [i, j], msg)

		msg = "%s: matches[%s]['token'] == '%s'" % [prefix, k, pattern]
		assert_true(_match['token'] == pattern, msg)

		for prop_name in props:
			var prop_msg = props[prop_name][k]
			if prop_msg is String:
				prop_msg = "'%s'" % prop_msg
			var _msg = "%s: matches[%s].%s == %s" % [prefix, k, prop_name, prop_msg]
			assert_eq_deep(_match[prop_name], props[prop_name][k])

func test_build_ranked_dict():
	var rd = Matching.build_ranked_dict(['a', 'b', 'c', ])
	assert_eq_shallow(rd, {
		'a': 1,
		'b': 2,
		'c': 3,
	})

func test_add_frequency_lists():
	Matching.add_frequency_lists({
		'test_words': ['qidkviflkdoejjfkd', 'sjdshfidssdkdjdhfkl']
	})

	assert_true('test_words' in Matching.RANKED_DICTIONARIES, "")
	assert_eq_shallow(Matching.RANKED_DICTIONARIES['test_words'], {
		'qidkviflkdoejjfkd': 1,
		'sjdshfidssdkdjdhfkl': 2,
	})

func test_matching_utils():
	var chr_map = {
		'a': 'A',
		'b': 'B',
	}

	for arr in [
		['a', chr_map, 'A'],
		['c', chr_map, 'c'],
		['ab', chr_map, 'AB'],
		['abc', chr_map, 'ABc'],
		['aa', chr_map, 'AA'],
		['abab', chr_map, 'ABAB'],
		['', chr_map, ''],
		['', {}, ''],
		['abc', {}, 'abc'],
	]:
		assert_true(Matching.translate(arr[0], arr[1]) == arr[2], \
			"translates '%s' to '%s' with provided charmap" % [arr[0], arr[2]])

func dm(pw, test_dicts):
		return Matching.dictionary_match(pw, test_dicts)

func test_dictionary_matching():
	var test_dicts = {
		'd1': {
			'motherboard': 1,
			'mother': 2,
			'board': 3,
			'abcd': 4,
			'cdef': 5,
		},
		'd2': {
			'z': 1,
			'8': 2,
			'99': 3,
			'$': 4,
			'asdf1234&*': 5,
		}
	}

	var matches = dm('motherboard', test_dicts)
	var patterns = ['mother', 'motherboard', 'board']
	var msg = 'matches words that contain other words'
	check_matches(msg, matches, 'dictionary', patterns,
				  [[0, 5], [0, 10], [6, 10]], {
					  'matched_word': ['mother', 'motherboard', 'board'],
					  'rank': [2, 1, 3],
					  'dictionary_name': ['d1', 'd1', 'd1'],
				  })

	matches = dm('abcdef', test_dicts)
	patterns = ['abcd', 'cdef']
	msg = "matches multiple words when they overlap"
	check_matches(msg, matches, 'dictionary', patterns, [[0, 3], [2, 5]], {
		'matched_word': ['abcd', 'cdef'],
		'rank': [4, 5],
		'dictionary_name': ['d1', 'd1'],
	})

	matches = dm('BoaRdZ', test_dicts)
	patterns = ['BoaRd', 'Z']
	msg = "ignores uppercasing"
	check_matches(msg, matches, 'dictionary', patterns, [[0, 4], [5, 5]], {
		'matched_word': ['board', 'z'],
		'rank': [3, 1],
		'dictionary_name': ['d1', 'd2'],
	})

	var prefixes = ['q', '%%']
	var suffixes = ['%', 'qq']
	var word = 'asdf1234&*'
	for pij in genpws(word, prefixes, suffixes):
		matches = dm(pij[0], test_dicts)
		msg = "identifies words surrounded by non-words"
		check_matches(msg, matches, 'dictionary', [word], [[pij[1], pij[2]]], {
			'matched_word': [word],
			'rank': [5],
			'dictionary_name': ['d2'],
		})

	for dname in test_dicts.keys():
		for _word in test_dicts[dname].keys():
			if _word == 'motherboard':
				continue  # skip words that contain others
			matches = dm(_word, test_dicts)
			msg = "matches against all words in provided dictionaries"
			check_matches(msg, matches, 'dictionary', [_word],
						  [[0, len(_word) - 1]], {
							  'matched_word': [_word],
							  'rank': [test_dicts[dname][_word]],
							  'dictionary_name': [dname],
						  })

	# test the default dictionaries
	matches = Matching.dictionary_match('wow')
	patterns = ['wow']
	var ijs = [[0, 2]]
	msg = "default dictionaries"
	check_matches(msg, matches, 'dictionary', patterns, ijs, {
		'matched_word': patterns,
		'rank': [322],
		'dictionary_name': ['us_tv_and_film'],
	})

func test_reverse_dictionary_matching():
	var test_dicts = {
		'd1': {
			'123': 1,
			'321': 2,
			'456': 3,
			'654': 4,
		}
	}
	var password = '0123456789'
	var matches = Matching.reverse_dictionary_match(password, test_dicts)
	var msg = 'matches against reversed words'
	check_matches(msg, matches, 'dictionary', ['123', '456'], [[1, 3], [4, 6]],
				  {
					  'matched_word': ['321', '654'],
					  'reversed': [true, true],
					  'dictionary_name': ['d1', 'd1'],
					  'rank': [2, 4],
				  })

enum { PASSWORD, PATTERN, WORD, DICTIONARY_NAME, RANK, IJ, SUB }
func test_l33t_matching():
	var test_table = {
		'a': ['4', '@'],
		'c': ['(', '{', '[', '<'],
		'g': ['6', '9'],
		'o': ['0'],
	}
	for pair in [
		['', {}],
		['abcdefgo123578!#$&*)]}>', {}],
		['a', {}],
		['4', {'a': ['4']}],
		['4@', {'a': ['4', '@']}],
		['4({60', {'a': ['4'], 'c': ['(', '{'], 'g': ['6'], 'o': ['0']}],
	]:
		var _msg = "reduces l33t table to only the substitutions that a password might be employing"
		assert_eq_deep(Matching.relevant_l33t_subtable(pair[0], test_table), pair[1])

	for pair in [
		[{}, [{}]],
		[{'a': ['@']}, [{'@': 'a'}]],
		[{'a': ['@', '4']}, [{'@': 'a'}, {'4': 'a'}]],
		[{'a': ['@', '4'], 'c': ['(']}, [{'@': 'a', '(': 'c'}, {'4': 'a', '(': 'c'}]],
	]:
		var _msg = "enumerates the different sets of l33t substitutions a password might be using"
		assert_eq_deep(Matching.enumerate_l33t_subs(pair[0]), pair[1])

	var dicts = {
		'words': {
			'aac': 1,
			'password': 3,
			'paassword': 4,
			'asdf0': 5,
		},
		'words2': {
			'cgo': 1,
		}
	}
	assert_true(Matching.l33t_match('', dicts, test_table) == [], "doesn't match ''")
	assert_true(Matching.l33t_match('password', dicts, test_table) == [], "doesn't match pure dictionary words")
	for items in [
		['p4ssword', 'p4ssword', 'password', 'words', 3, [0, 7], {'4': 'a'}],
		['p@ssw0rd', 'p@ssw0rd', 'password', 'words', 3, [0, 7], {'@': 'a', '0': 'o'}],
		['aSdfO{G0asDfO', '{G0', 'cgo', 'words2', 1, [5, 7], {'{': 'c', '0': 'o'}],
	]:
		var msg = "matches against common l33t substitutions"
		check_matches(msg, Matching.l33t_match(items[PASSWORD], dicts, test_table), 'dictionary', [items[PATTERN]], [items[IJ]],
					  {
						  'l33t': [true],
						  'sub': [items[SUB]],
						  'matched_word': [items[WORD]],
						  'rank': [items[RANK]],
						  'dictionary_name': [items[DICTIONARY_NAME]],
					  })

	var matches = Matching.l33t_match('@a(go{G0', dicts, test_table)
	var msg = "matches against overlapping l33t patterns"
	check_matches(msg, matches, 'dictionary', ['@a(', '(go', '{G0'],
				  [[0, 2], [2, 4], [5, 7]], {
					  'l33t': [true, true, true],
					  'sub': [{'@': 'a', '(': 'c'}, {'(': 'c'},
							  {'{': 'c', '0': 'o'}],
					  'matched_word': ['aac', 'cgo', 'cgo'],
					  'rank': [1, 1, 1],
					  'dictionary_name': ['words', 'words2', 'words2'],
				  })

	msg = "doesn't match when multiple l33t substitutions are needed for the same letter"
	assert_true(Matching.l33t_match('p4@ssword', dicts, test_table) == [], msg)

	msg = "doesn't match single-character l33ted words"
	matches = Matching.l33t_match('4 1 @')
	assert_true(matches == [], msg)

	# known issue: subsets of substitutions aren't tried.
	# for long inputs, trying every subset of every possible substitution could quickly get large,
	# but there might be a performant way to fix.
	# (so in this example: {'4': a, '0': 'o'} is detected as a possible sub,
	# but the subset {'4': 'a'} isn't tried, missing the match for asdf0.)
	# TODO: consider partially fixing by trying all subsets of size 1 and maybe 2
	msg = "doesn't match with subsets of possible l33t substitutions"
	assert_true(Matching.l33t_match('4sdf0', dicts, test_table) == [], msg)

enum { PATTERN2, KEYBOARD, TURNS, SHIFTS }
func test_spatial_matching():
	var msg = "doesn't match 1- and 2-character spatial patterns"
	for password in ['', '/', 'qw', '*/']:
		assert_true(Matching.spatial_match(password) == [], msg)

	# for testing, make a subgraph that contains a single keyboard
	var _graphs = {'qwerty': AdjacencyGraphs.data['qwerty']}
	var pattern = '6tfGHJ'
	var matches = Matching.spatial_match("rz!%s%%z" % pattern, _graphs)
	msg = "matches against spatial patterns surrounded by non-spatial patterns"
	check_matches(msg, matches, 'spatial', [pattern],
				  [[3, 3 + len(pattern) - 1]],
				  {
					  'graph': ['qwerty'],
					  'turns': [2],
					  'shifted_count': [3],
				  })

	for _data in [
		['12345', 'qwerty', 1, 0],
		['@WSX', 'qwerty', 1, 4],
		['6tfGHJ', 'qwerty', 2, 3],
		['hGFd', 'qwerty', 1, 2],
		['/;p09876yhn', 'qwerty', 3, 0],
		['Xdr%', 'qwerty', 1, 2],
		['159-', 'keypad', 1, 0],
		['*84', 'keypad', 1, 0],
		['/8520', 'keypad', 1, 0],
		['369', 'keypad', 1, 0],
		['/963.', 'mac_keypad', 1, 0],
		['*-632.0214', 'mac_keypad', 9, 0],
		['aoEP%yIxkjq:', 'dvorak', 4, 5],
		[';qoaOQ:Aoq;a', 'dvorak', 11, 4],
	]:
		_graphs = {_data[KEYBOARD]: AdjacencyGraphs.data[_data[KEYBOARD]]}
		matches = Matching.spatial_match(_data[PATTERN2], _graphs)
		msg = "matches '%s' as a %s pattern" % [_data[PATTERN2], _data[KEYBOARD]]
		check_matches(msg, matches, 'spatial', [_data[PATTERN2]],
					  [[0, len(_data[PATTERN2]) - 1]],
					  {
						  'graph': [_data[KEYBOARD]],
						  'turns': [_data[TURNS]],
						  'shifted_count': [_data[SHIFTS]],
					  })

enum { PASSWORD2, I, J }
func test_sequence_matching():
	var msg = "doesn't match length-#{len(password)} sequences"
	for password in ['', 'a', '1']:
		assert_true(Matching.sequence_match(password) == [], msg)

	var matches = Matching.sequence_match('abcbabc')
	msg = "matches overlapping patterns"
	check_matches(msg, matches, 'sequence', ['abc', 'cba', 'abc'],
				  [[0, 2], [2, 4], [4, 6]],
				  {'ascending': [true, false, true]})

	var prefixes = ['!', '22']
	var suffixes = ['!', '22']
	var pattern = 'jihg'
	for _data in genpws(pattern, prefixes, suffixes):
		matches = Matching.sequence_match(_data[PASSWORD])
		msg = 'matches embedded sequence patterns'
		check_matches(msg, matches, 'sequence', [pattern], [[_data[I], _data[J]]],
					  {
						  'sequence_name': ['lower'],
						  'ascending': [false],
					  })

	for _data in [
		['ABC', 'upper', true],
		['CBA', 'upper', false],
		['PQR', 'upper', true],
		['RQP', 'upper', false],
		['XYZ', 'upper', true],
		['ZYX', 'upper', false],
		['abcd', 'lower', true],
		['dcba', 'lower', false],
		['jihg', 'lower', false],
		['wxyz', 'lower', true],
		['zxvt', 'lower', false],
		['0369', 'digits', true],
		['97531', 'digits', false],
	]:
		matches = Matching.sequence_match(_data[0])
		msg = "matches '#{pattern}' as a '#{name}' sequence"
		check_matches(msg, matches, 'sequence', [_data[0]],
					  [[0, len(_data[0]) - 1]],
					  {
						  'sequence_name': [_data[1]],
						  'ascending': [_data[2]],
					  })

func test_repeat_matching():
	var msg
	for password in ['', '#']:
		msg = "doesn't match length-%s repeat patterns" % len(password)
		assert_true(Matching.repeat_match(password) == [], msg)

	# test single-character repeats
	var prefixes = ['@', 'y4@']
	var suffixes = ['u', 'u%7']
	var pattern = '&&&&&'
	for _data in genpws(pattern, prefixes, suffixes):
		var matches = Matching.repeat_match(_data[0])
		msg = "matches embedded repeat patterns"
		check_matches(msg, matches, 'repeat', [_data[0]], [[_data[1], _data[2]]],
					  {'base_token': ['&']})

	for length in [3, 12]:
		for chr in ['a', 'Z', '4', '&']:
			pattern = chr * (length + 1)
			var matches = Matching.repeat_match(pattern)
			msg = "matches repeats with base character '%s'" % chr
			check_matches(msg, matches, 'repeat', [pattern],
						  [[0, len(pattern) - 1]],
						  {'base_token': [chr]})

	var matches = Matching.repeat_match('BBB1111aaaaa@@@@@@')
	var patterns = ['BBB', '1111', 'aaaaa', '@@@@@@']
	msg = 'matches multiple adjacent repeats'
	check_matches(msg, matches, 'repeat', patterns,
				  [[0, 2], [3, 6], [7, 11], [12, 17]],
				  {'base_token': ['B', '1', 'a', '@']})

	matches = Matching.repeat_match('2818BBBbzsdf1111@*&@!aaaaaEUDA@@@@@@1729')
	msg = 'matches multiple repeats with non-repeats in-between'
	check_matches(msg, matches, 'repeat', patterns,
				  [[4, 6], [12, 15], [21, 25], [30, 35]],
				  {'base_token': ['B', '1', 'a', '@']})

	# test multi-character repeats
	pattern = 'abab'
	matches = Matching.repeat_match(pattern)
	msg = 'matches multi-character repeat pattern'
	check_matches(msg, matches, 'repeat', [pattern], [[0, len(pattern) - 1]],
				  {'base_token': ['ab']})

	pattern = 'aabaab'
	matches = Matching.repeat_match(pattern)
	msg = 'matches aabaab as a repeat instead of the aa prefix'
	check_matches(msg, matches, 'repeat', [pattern], [[0, len(pattern) - 1]],
				  {'base_token': ['aab']})

	pattern = 'abababab'
	matches = Matching.repeat_match(pattern)
	msg = 'identifies ab as repeat string, even though abab is also repeated'
	check_matches(msg, matches, 'repeat', [pattern], [[0, len(pattern) - 1]],
				  {'base_token': ['ab']})
