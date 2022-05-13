#from zxcvbn.scoring import START_UPPER, ALL_UPPER
#from gettext import gettext as _


func get_feedback(score, sequence: Array):
	if len(sequence) == 0:
		return {
			'warning': '',
			'suggestions': [
				_("Use a few words, avoid common phrases."),
				_("No need for symbols, digits, or uppercase letters.")
			]
		}

	if score > 2:
		return {
			'warning': '',
			'suggestions': [],
		}

	var longest_match = sequence[0]
	for _match in sequence.slice(1, -1):
		if len(_match['token']) > len(longest_match['token']):
			longest_match = _match

	var feedback = get_match_feedback(longest_match, len(sequence) == 1)
	var extra_feedback = _('Add another word or two. Uncommon words are better.')
	if feedback:
		feedback['suggestions'].insert(0, extra_feedback)
		if not feedback['warning']:
			feedback['warning'] = ''
	else:
		feedback = {
			'warning': '',
			'suggestions': [extra_feedback]
		}

	return feedback


func get_match_feedback(_match, is_sole_match):
	var warning
	if _match['pattern'] == 'dictionary':
		return get_dictionary_match_feedback(_match, is_sole_match)
	elif _match['pattern'] == 'spatial':
		if _match['turns'] == 1:
			warning = _('Straight rows of keys are easy to guess.')
		else:
			warning = _('Short keyboard patterns are easy to guess.')

		return {
			'warning': warning,
			'suggestions': [
				_('Use a longer keyboard pattern with more turns.')
			]
		}
	elif _match['pattern'] == 'repeat':
		if len(_match['base_token']) == 1:
			warning = _('Repeats like "aaa" are easy to guess.')
		else:
			warning = _('Repeats like "abcabcabc" are only slightly harder to guess than "abc".')
		return {
			'warning': warning,
			'suggestions': [
				_('Avoid repeated words and characters.')
			]
		}
	elif _match['pattern'] == 'sequence':
		return {
			'warning': _('Sequences like "abc" or "6543" are easy to guess.'),
			'suggestions': [
				_('Avoid sequences.')
			]
		}
	elif _match['pattern'] == 'regex':
		if _match['regex_name'] == 'recent_year':
			return {
				'warning': _("Recent years are easy to guess."),
				'suggestions': [
					_('Avoid recent years.'),
					_('Avoid years that are associated with you.'),
				]
			}
	elif _match['pattern'] == 'date':
		return {
			'warning': _("Dates are often easy to guess."),
			'suggestions': [
				_('Avoid dates and years that are associated with you.'),
			],
		}


func get_dictionary_match_feedback(_match, is_sole_match):
	var warning = ''
	if _match['dictionary_name'] == 'passwords':
		if is_sole_match and not _match.get('l33t', false) and not \
				_match['reversed']:
			if _match['rank'] <= 10:
				warning = _('This is a top-10 common password.')
			elif _match['rank'] <= 100:
				warning = _('This is a top-100 common password.')
			else:
				warning = _('This is a very common password.')
		elif _match['guesses_log10'] <= 4:
			warning = _('This is similar to a commonly used password.')
	elif _match['dictionary_name'] == 'english_wikipedia':
		if is_sole_match:
			warning = _('A word by itself is easy to guess.')
	elif _match['dictionary_name'] in ['surnames', 'male_names',
									  'female_names', ]:
		if is_sole_match:
			warning = _('Names and surnames by themselves are easy to guess.')
		else:
			warning = _('Common names and surnames are easy to guess.')
	else:
		warning = ''

	var suggestions = []
	var word = _match['token']
	if Scoring.START_UPPER.search(word):
		suggestions.append(_("Capitalization doesn't help very much."))
	elif Scoring.ALL_UPPER.search(word) and word.lower() != word:
		suggestions.append(_("All-uppercase is almost as easy to guess as all-lowercase."))

	if _match['reversed'] and len(_match['token']) >= 4:
		suggestions.append(_("Reversed words aren't much harder to guess."))
	if _match.get('l33t', false):
		suggestions.append(_("Predictable substitutions like '@' instead of 'a' don't help very much."))

	return {
		'warning': warning,
		'suggestions': suggestions,
	}

func _(s):
	return s
