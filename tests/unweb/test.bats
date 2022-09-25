load ../test_setup.bash

setup_file() {
	$DOCTL sbx deploy $BATS_TEST_DIRNAME
}

teardown_file() {
	delete_package "test-unweb"
}

@test "deploy project with default web values" {
	run $DOCTL sbx fn get test-unweb/notify
	assert_success
	assert_output --partial '{
      "key": "web-export",
      "value": true
    },'
	assert_output --partial '{
      "key": "require-whisk-auth",
      "value": false
    },'
	$DOCTL sbx deploy $BATS_TEST_DIRNAME/unweb-with-config
  run $DOCTL sbx fn get test-unweb/notify
	assert_success
	assert_output --partial '{
      "key": "web-export",
      "value": false
    },'
	assert_output --partial '{
      "key": "require-whisk-auth",
      "value": "xyzzy"
    },'
}
