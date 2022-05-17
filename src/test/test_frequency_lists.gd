extends GutTest

func test_frequency_lists():
	assert_true(FrequencyLists.data is Dictionary, "Should contain a dictionary")
	assert_true(FrequencyLists.data.has('passwords'), "Should have 'passwords'")
	assert_true(FrequencyLists.data.has('english_wikipedia'), "Should have 'english_wikipedia'")
	assert_true(FrequencyLists.data.has('female_names'), "Should have 'female_names'")
	assert_true(FrequencyLists.data.has('surnames'), "Should have 'surnames'")
	assert_true(FrequencyLists.data.has('us_tv_and_film'), "Should have 'us_tv_and_film'")
	assert_true(FrequencyLists.data.has('male_names'), "Should have 'male_names'")
