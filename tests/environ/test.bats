load ../test_setup.bash

get_action_kind () {
	$DOCTL sbx fn get test_environ/variable | jq -r .exec.kind
}

teardown_file() {
	delete_package "test_environ"
}

@test "deploying project using '.env' default" {
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME
	assert_success
	run get_action_kind
	assert_output "nodejs:14"
}

@test "deploying project using alternative file 'test.env'" {
	unset RUNTIME
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME --env $BATS_TEST_DIRNAME/test.env
	assert_success
	run get_action_kind
	assert_output "nodejs-lambda:14"
}

@test "deploying project using an environment variable" {
	export RUNTIME='python:3.9'
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME
	assert_success
	run get_action_kind
	assert_output "python:3.9"
}
