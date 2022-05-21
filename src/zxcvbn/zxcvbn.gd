extends Node

func zxcvbn(password, user_inputs = []):
	var start = OS.get_ticks_msec()
	var sanitized_inputs = user_inputs
	var ranked_dictionaries = Matching.RANKED_DICTIONARIES
	ranked_dictionaries['user_inputs'] = Matching.build_ranked_dict(sanitized_inputs)

	var matches = Matching.omnimatch(password, ranked_dictionaries)
	var result = Scoring.most_guessable_match_sequence(password, matches)
	result['calc_time'] = OS.get_ticks_msec() - start

	var attack_times = TimeEstimates.estimate_attack_times(result['guesses'])
	for prop in attack_times.keys():
		result[prop] = attack_times[prop]

	result['feedback'] = Feedback.get_feedback(result['score'], result['sequence'])

	return result

