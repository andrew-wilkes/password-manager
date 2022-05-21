extends GutTest

func test_matching_build_ranked_dict():
	var mrd = Matching.RANKED_DICTIONARIES
	assert_true(mrd.size() > 0, "Should have dictionary")
	assert_true(mrd["passwords"].size() > 1000, "Should have passwords")
	var pw_key = mrd["passwords"].keys()[0]
	assert_true(pw_key is String, "Key should be a string")
	assert_true(mrd["passwords"][pw_key] is int, "Value should be an integer")

func test_unicode_user_inputs():
	# test Issue #12 -- don't raise a UnicodeError with unicode user_inputs or
	# passwords.
	var input_ = 'Фамилия'
	var password = 'pÄssword junkiË'

	ZXCVBN.zxcvbn(password, [input_])


func test_invalid_user_inputs():
	# don't raise an error with non-string types for user_inputs
	var input_ = null
	var password = 'pÄssword junkiË'

	ZXCVBN.zxcvbn(password, [input_])


func test_long_password():
	var input_ = null
	var password = "weopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioejiojweopiopdsjmkldjvoisdjfioej"

	ZXCVBN.zxcvbn(password, [input_])


func test_dictionary_password():
	# return the correct error message for a english match
	var input_ = null
	var password = "musculature"

	var result = ZXCVBN.zxcvbn(password, [input_])

	assert_eq(result["feedback"]["warning"], \
		   "A word by itself is easy to guess.", \
		   "Gives specific error for single-word passwords")
