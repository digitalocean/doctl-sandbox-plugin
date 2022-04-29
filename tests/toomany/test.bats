load ../test_setup.bash
ACTION_COUNT=100

teardown_file() {
  delete_package "test-toomany"
	rm -fr $BATS_TEST_DIRNAME/packages
}

@test "deploy a project with $ACTION_COUNT actions" {
	rm -fr $BATS_TEST_DIRNAME/packages
  mkdir -p $BATS_TEST_DIRNAME/packages/test-toomany
	for i in $(seq 1 $ACTION_COUNT); do touch $BATS_TEST_DIRNAME/packages/test-toomany/h$i.js; done
  run $DOCTL sbx deploy $BATS_TEST_DIRNAME
  assert_success
  COUNT=$(echo "$output" | grep -o '\- test-toomany/h' | wc -l) 
  assert [ $COUNT == $ACTION_COUNT ]  
}