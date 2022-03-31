load ../test_setup.bash

setup_file() {
	$DOCTL sbx deploy $BATS_TEST_DIRNAME
}

teardown_file() {
	delete_package "test-sequence"
}

@test "invoking sequence runs individual actions" {
	run $DOCTL sbx fn invoke test-sequence/mySequence --param-file $BATS_TEST_DIRNAME/sushi.json
	assert_success
	assert_output '{
  "length": 3,
  "lines": [
    "Is full of regret.",
    "Over-ripe sushi,",
    "The Master"
  ]
}'
  run $DOCTL sbx fn invoke test-sequence/incrFiveTimes -p value:0
	assert_success
	assert_output '{
  "value": 5
}'
}
