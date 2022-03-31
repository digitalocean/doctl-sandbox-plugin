load ../test_setup.bash

@test "deploying project with nothing to deploy" {
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME
	assert_success
	assert_output --partial "Nothing deployed"
}
