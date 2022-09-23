load ../test_setup.bash

teardown_file() {
	delete_package "test-triggers"
}

@test "deploy a project with valid trigger clause" {
  run $DOCTL sls deploy $BATS_TEST_DIRNAME
	assert_success
}

@test "ensure that the just-created trigger is actually present" {
  run bash -c "$DOCTL sls trig get sayit | jq -r .triggerName"
  assert_success
  assert_output sayit
}

@test "ensure that undeploying a function with a trigger deletes its trigger also" {
  run $DOCTL sls undeploy test-triggers/hello
  assert_success
  run bash -c "$DOCTL sls trig get sayit | jq -r .error.status"
  assert_output -p 404
}
