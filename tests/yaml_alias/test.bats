load ../test_setup.bash

setup_file() {
	$DOCTL sbx deploy $BATS_TEST_DIRNAME
}

teardown_file() {
	delete_package "test-yaml-alias"
}

@test "deploy project with config containing YAML aliases" {
	run $DOCTL sbx fn get test-yaml-alias/gateway
	assert_success
	assert_output --partial '{
      "key": "require-whisk-auth",
      "value": false
    },'
	run $DOCTL sbx fn get test-yaml-alias/cli-gateway
	assert_success
	assert_output --partial '{
      "key": "require-whisk-auth",
      "value": true
    },'
}
