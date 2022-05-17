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
	for k in range(len(patterns)):
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

		for prop_name in props.keys():
			var prop_msg = props[prop_name][k]
			if prop_msg is String:
				prop_msg = "'%s'" % prop_msg
			msg = "%s: matches[%s].%s == %s" % [prefix, k, prop_name, prop_msg]
			assert_true(_match[prop_name] == prop_msg, msg)

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
