extends GutTest

func test_matching_build_ranked_dict():
	var mrd = Matching.RANKED_DICTIONARIES
	assert_true(mrd.size() > 0, "Should have dictionary")
	assert_true(mrd["passwords"].size() > 1000, "Should have passwords")
	var pw_key = mrd["passwords"].keys()[0]
	assert_true(pw_key is String, "Key should be a string")
	assert_true(mrd["passwords"][pw_key] is int, "Value should be an integer")
