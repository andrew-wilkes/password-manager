extends Node

const START_UPPER = "^[A-Z][^A-Z]+$"
const END_UPPER = "^[^A-Z]+[A-Z]$"
const ALL_UPPER = "^[^a-z]+$"
const ALL_LOWER = "^[^A-Z]+$"

var KEYBOARD_AVERAGE_DEGREE = calc_average_degree(AdjacencyGraphs.data['qwerty'])
# slightly different for keypad/mac keypad, but close enough
var KEYPAD_AVERAGE_DEGREE = calc_average_degree(AdjacencyGraphs.data['keypad'])

var KEYBOARD_STARTING_POSITIONS = len(AdjacencyGraphs.data['qwerty'].keys())
var KEYPAD_STARTING_POSITIONS = len(AdjacencyGraphs.data['keypad'].keys())

class MatchSorter:
	static func sort_by_i(ma, mb):
		return ma['i'] < mb['i']

func calc_average_degree(graph):
	var average = 0
	# Python: average += len([n for n in neighbors if n])
	for neighbors in graph.values():
		for n in neighbors:
			if n:
				average += 1
	average /= float(graph.size())
	return average


const BRUTEFORCE_CARDINALITY = 10
const MIN_GUESSES_BEFORE_GROWING_SEQUENCE = 10000
const MIN_SUBMATCH_GUESSES_SINGLE_CHAR = 10
const MIN_SUBMATCH_GUESSES_MULTI_CHAR = 50

const MIN_YEAR_SPACE = 20
const REFERENCE_YEAR = 2017


func nCk(n, k):
	"""http://blog.plover.com/math/choose.html"""
	if k > n:
		return 0
	if k == 0:
		return 1

	var r = 1
	for d in range(1, k + 1):
		r *= n
		r /= d
		n -= 1

	return r


# ------------------------------------------------------------------------------
# search --- most guessable _match sequence -------------------------------------
# ------------------------------------------------------------------------------
#
# takes a sequence of overlapping matches, returns the non-overlapping sequence with
# minimum guesses. the following is a O(l_max * (n + m)) dynamic programming algorithm
# for a length-n password with m candidate matches. l_max is the maximum optimal
# sequence length spanning each prefix of the password. In practice it rarely exceeds 5 and the
# search terminates rapidly.
#
# the optimal "minimum guesses" sequence is here defined to be the sequence that
# minimizes the following function:
#
#    g = l! * Product(m.guesses for m in sequence) + D^(l - 1)
#
# where l is the length of the sequence.
#
# the factorial term is the number of ways to order l patterns.
#
# the D^(l-1) term is another length penalty, roughly capturing the idea that an
# attacker will try lower-length sequences first before trying length-l sequences.
#
# for example, consider a sequence that is date-repeat-dictionary.
#  - an attacker would need to try other date-repeat-dictionary combinations,
#    hence the product term.
#  - an attacker would need to try repeat-date-dictionary, dictionary-repeat-date,
#    ..., hence the factorial term.
#  - an attacker would also likely try length-1 (dictionary) and length-2 (dictionary-date)
#    sequences before length-3. assuming at minimum D guesses per pattern type,
#    D^(l-1) approximates Sum(D^i for i in [1..l-1]
#
# ------------------------------------------------------------------------------
func most_guessable_match_sequence(password, matches, _exclude_additive = false):
	var n = len(password)

	# partition matches into sublists according to ending index j
	var matches_by_j = []
	for _n in n:
		matches_by_j.append([])
	for m in matches:
		matches_by_j[m['j']].append(m)
	# small detail: for deterministic output, sort each sublist by i.
	for lst in matches_by_j:
		lst.sort_custom(MatchSorter, "sort_by_i")

	var optimal = {
	# optimal.m[k][l] holds final _match in the best length-l _match sequence
	# covering the password prefix up to k, inclusive.
	# if there is no length-l sequence that scores better (fewer guesses)
	# than a shorter _match sequence spanning the same prefix,
	# optimal.m[k][l] is undefined.
	'm': get_array_of_dictionaries(n),

	# same structure as optimal.m -- holds the product term Prod(m.guesses
	# for m in sequence). optimal.pi allows for fast (non-looping) updates
	# to the minimization function.
	'pi': get_array_of_dictionaries(n),

	# same structure as optimal.m -- holds the overall metric.
	'g': get_array_of_dictionaries(n),
	}

	for k in range(n):
		for m in matches_by_j[k]:
			if m['i'] > 0:
				for l in optimal['m'][m['i'] - 1]:
					l = int(l)
					update(m, l + 1, password, _exclude_additive, optimal)
			else:
				update(m, 1, password, _exclude_additive, optimal)
		bruteforce_update(k, password, _exclude_additive, optimal)

	var optimal_match_sequence = unwind(n, optimal)
	var optimal_l = len(optimal_match_sequence)

	# corner: empty password
	var guesses
	if len(password) == 0:
		guesses = 1
	else:
		guesses = optimal['g'][n - 1][optimal_l]

	# final result object
	return {
		'password': password,
		'guesses': guesses,
		'guesses_log10': log(guesses) / 2.303,
		'sequence': optimal_match_sequence,
	}


func get_array_of_dictionaries(n):
	var array = []
	for _n in n:
		array.append({})
	return array


# helper: considers whether a length-l sequence ending at _match m is better
# (fewer guesses) than previously encountered sequences, updating state if
# so.
func update(m, l, password, _exclude_additive, optimal):
	var k = m['j']
	var pi = estimate_guesses(m, password)
	if l > 1:
		# we're considering a length-l sequence ending with _match m:
		# obtain the product term in the minimization function by
		# multiplying m's guesses by the product of the length-(l-1)
		# sequence ending just before m, at m.i - 1.
		pi = pi * Decimal(optimal['pi'][m['i'] - 1][l - 1])
	# calculate the minimization func
	var g = factorial(l) * pi
	if not _exclude_additive:
		g += pow(MIN_GUESSES_BEFORE_GROWING_SEQUENCE, (l - 1))

	# update state if new best.
	# first see if any competing sequences covering this prefix, with l or
	# fewer matches, fare better than this sequence. if so, skip it and
	# return.
	for competing_l in optimal['g'][k]:
		var competing_g = optimal['g'][k][competing_l]
		if competing_l > l:
			continue
		if competing_g <= g:
			return

	# this sequence might be part of the final optimal sequence.
	optimal['g'][k][l] = g
	optimal['m'][k][l] = m
	optimal['pi'][k][l] = pi

# helper: evaluate bruteforce matches ending at k.
func bruteforce_update(k, password, _exclude_additive, optimal):
	# see if a single bruteforce _match spanning the k-prefix is optimal.
	var m = make_bruteforce_match(0, k, password)
	update(m, 1, password, _exclude_additive, optimal)
	for i in range(1, k + 1):
		# generate k bruteforce matches, spanning from (i=1, j=k) up to
		# (i=k, j=k). see if adding these new matches to any of the
		# sequences in optimal[i-1] leads to new bests.
		m = make_bruteforce_match(i, k, password)
		for l in optimal['m'][i - 1].items().keys():
			var last_m = optimal['m'][i - 1].items()[l]
			l = int(l)

			# corner: an optimal sequence will never have two adjacent
			# bruteforce matches. it is strictly better to have a single
			# bruteforce _match spanning the same region: same contribution
			# to the guess product with a lower length.
			# --> safe to skip those cases.
			if last_m.get('pattern', false) == 'bruteforce':
				continue

			# try adding m to this length-l sequence.
			update(m, l + 1, password, _exclude_additive, optimal)

# helper: make bruteforce _match objects spanning i to j, inclusive.
func make_bruteforce_match(i, j, password):
	return {
		'pattern': 'bruteforce',
		'token': password.substr(i, j - i + 1),
		'i': i,
		'j': j,
	}

# helper: step backwards through optimal.m starting at the end,
# constructing the final optimal _match sequence.
func unwind(n, optimal):
	var optimal_match_sequence = []
	var k = n - 1
	# find the final best sequence length and score
	var l = null
	var g = float(INF)
	for candidate_l in optimal['g'][k]:
		var candidate_g = optimal['g'][k][candidate_l]
		if candidate_g < g:
			l = candidate_l
			g = candidate_g

	while k >= 0:
		var m = optimal['m'][k][l]
		optimal_match_sequence.insert(0, m)
		k = m['i'] - 1
		l -= 1

	return optimal_match_sequence

func estimate_guesses(_match, password):
	if _match.get('guesses', false):
		return Decimal(_match['guesses'])

	var min_guesses = 1
	if len(_match['token']) < len(password):
		if len(_match['token']) == 1:
			min_guesses = MIN_SUBMATCH_GUESSES_SINGLE_CHAR
		else:
			min_guesses = MIN_SUBMATCH_GUESSES_MULTI_CHAR

	var estimation_functions = {
		'bruteforce': "bruteforce_guesses",
		'dictionary': "dictionary_guesses",
		'spatial': "spatial_guesses",
		'repeat': "repeat_guesses",
		'sequence': "sequence_guesses",
		'regex': "regex_guesses",
		'date': "date_guesses",
	}

	var guesses = callv(estimation_functions[_match['pattern']], [_match])
	_match['guesses'] = max(guesses, min_guesses)
	_match['guesses_log10'] = log(_match['guesses']) / 2.303

	return Decimal(_match['guesses'])


func bruteforce_guesses(_match):
	var guesses = pow(BRUTEFORCE_CARDINALITY, len(_match['token']))
	# small detail: make bruteforce matches at minimum one guess bigger than
	# smallest allowed submatch guesses, such that non-bruteforce submatches
	# over the same [i..j] take precedence.
	var min_guesses
	if len(_match['token']) == 1:
		min_guesses = MIN_SUBMATCH_GUESSES_SINGLE_CHAR + 1
	else:
		min_guesses = MIN_SUBMATCH_GUESSES_MULTI_CHAR + 1

	return max(guesses, min_guesses)


func dictionary_guesses(_match):
	# keep these as properties for display purposes
	_match['base_guesses'] = _match['rank']
	_match['uppercase_variations'] = uppercase_variations(_match)
	_match['l33t_variations'] = l33t_variations(_match)
	var reversed_variations = _match.get('reversed', false) and 2 or 1

	return _match['base_guesses'] * _match['uppercase_variations'] * \
		_match['l33t_variations'] * reversed_variations


func repeat_guesses(_match):
	return _match['base_guesses'] * Decimal(_match['repeat_count'])


func sequence_guesses(_match):
	var regex = RegEx.new()
	var first_chr = _match['token'].slice(1, -1)
	var base_guesses
	# lower guesses for obvious starting points
	if first_chr in ['a', 'A', 'z', 'Z', '0', '1', '9']:
		base_guesses = 4
	else:
		if regex.compile("\\d").search(first_chr):
			base_guesses = 10  # digits
		else:
			# could give a higher base for uppercase,
			# assigning 26 to both upper and lower sequences is more
			# conservative.
			base_guesses = 26
	if not _match['ascending']:
		base_guesses *= 2

	return base_guesses * len(_match['token'])


func regex_guesses(_match):
	var char_class_bases = {
		'alpha_lower': 26,
		'alpha_upper': 26,
		'alpha': 52,
		'alphanumeric': 62,
		'digits': 10,
		'symbols': 33,
	}
	if _match['regex_name'] in char_class_bases:
		return pow(char_class_bases[_match['regex_name']], len(_match['token']))
	elif _match['regex_name'] == 'recent_year':
		# conservative estimate of year space: num years from REFERENCE_YEAR.
		# if year is close to REFERENCE_YEAR, estimate a year space of
		# MIN_YEAR_SPACE.
		var year_space = abs(int(_match['regex_match'].get_string()) - REFERENCE_YEAR)
		year_space = max(year_space, MIN_YEAR_SPACE)

		return year_space


func date_guesses(_match):
	var year_space = max(abs(_match['year'] - REFERENCE_YEAR), MIN_YEAR_SPACE)
	var guesses = year_space * 365
	if _match.get('separator', false):
		guesses *= 4

	return guesses


func spatial_guesses(_match):
	var s
	var d
	var S
	var U
	if _match['graph'] in ['qwerty', 'dvorak']:
		s = KEYBOARD_STARTING_POSITIONS
		d = KEYBOARD_AVERAGE_DEGREE
	else:
		s = KEYPAD_STARTING_POSITIONS
		d = KEYPAD_AVERAGE_DEGREE
	var guesses = 0
	var L = len(_match['token'])
	var t = _match['turns']
	# estimate the number of possible patterns w/ length L or less with t turns
	# or less.
	for i in range(2, L + 1):
		var possible_turns = min(t, i - 1) + 1
		for j in range(1, possible_turns):
			guesses += nCk(i - 1, j - 1) * s * pow(d, j)
	# add extra guesses for shifted keys. (% instead of 5, A instead of a.)
	# math is similar to extra guesses of l33t substitutions in dictionary
	# matches.
	if _match['shifted_count']:
		S = _match['shifted_count']
		U = len(_match['token']) - _match['shifted_count']  # unshifted count
		if S == 0 or U == 0:
			guesses *= 2
		else:
			var shifted_variations = 0
			for i in range(1, min(S, U) + 1):
				shifted_variations += nCk(S + U, i)
			guesses *= shifted_variations

	return guesses


func uppercase_variations(_match):
	var word = _match['token']

	var regex = RegEx.new()
	regex.compile(ALL_LOWER)
	if  regex.search(word) or word.to_lower() == word:
		return 1

	for pattern in [START_UPPER, END_UPPER, ALL_UPPER]:
		regex.compile(pattern)
		if regex.search(word):
			return 2

	var U = 0 #sum(1 for c in word if c.isupper())
	var L = 0 #sum(1 for c in word if c.islower())
	for c in word:
		if c < "a":
			U += 1
		else:
			L += 1
	var variations = 0
	for i in range(1, min(U, L) + 1):
		variations += nCk(U + L, i)

	return variations


func l33t_variations(_match):
	if not _match['l33t']:
		return 1

	var variations = 1

	for subbed in _match['sub'].items().keys():
		var unsubbed = _match['sub'].items()[subbed]
		# lower-case _match.token before calculating: capitalization shouldn't
		# affect l33t calc.
		var chrs = _match['token'].lower()
		var S = 0
		var U = 0
		for c in chrs:
			if c == subbed:
				S += 1
			if c == unsubbed:
				U += 1
		if S == 0 or U == 0:
			# for this sub, password is either fully subbed (444) or fully
			# unsubbed (aaa) treat that as doubling the space (attacker needs
			# to try fully subbed chars in addition to unsubbed.)
			variations *= 2
		else:
			# this case is similar to capitalization:
			# with aa44a, U = 3, S = 2, attacker needs to try unsubbed + one
			# sub + two subs
			var p = min(U, S)
			var possibilities = 0
			for i in range(1, p + 1):
				possibilities += nCk(U + S, i)
			variations *= possibilities

	return variations


# Replacements for Python functions

func factorial(n: int):
	if n < 2: return 1
	if n > 2:
		for m in range(2, n):
			n *= m
	return n


func Decimal(n):
	return n
