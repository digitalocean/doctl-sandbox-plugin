load ../test_setup.bash

teardown_file() {
  if [ -n "$NO_TRIGGERS" ]; then
    return
  fi
	delete_package "test-triggers"
	$DOCTL sls undeploy --triggers --all
}

@test "deploying a project with triggers deploys the triggers" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  run $DOCTL sls deploy $BATS_TEST_DIRNAME
	assert_success
	run $DOCTL sls trig list
	assert_success
  assert_output -p invoke1
  assert_output -p invoke2	
}

@test "'triggers get' returns the expected data" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  INV1=$($DOCTL sls trig get invoke1 -ojson | jq -r '.[0]')
  NAME1=$(echo "$INV1" | jq -r .name)
  FCN1=$(echo "$INV1" | jq -r .function)
  ENAB1=$(echo "$INV1" | jq -r .is_enabled)
  CRON1=$(echo "$INV1" | jq -r .scheduled_details.cron)
  BODY1=$(echo "$INV1" | jq -r .scheduled_details.body)
  assert_equal "$NAME1"  invoke1
  assert_equal "$FCN1" test-triggers/hello1
  assert_equal "$ENAB1" true
  assert_equal "$CRON1" "* * * * *"
  refute [ "$BODY1" == null ]
  BODYNAME=$(echo "$BODY1" | jq -r .name)
  assert_equal "$BODYNAME" tester
  INV2=$($DOCTL sls trig get invoke2 -ojson | jq -r '.[0]')
  NAME2=$(echo "$INV2" | jq -r .name)
  FCN2=$(echo "$INV2" | jq -r .function)
  ENAB2=$(echo "$INV2" | jq -r .is_enabled)
  CRON2=$(echo "$INV2" | jq -r .scheduled_details.cron)
  BODY2=$(echo "$INV2" | jq -r .scheduled_details.body)
  assert_equal "$NAME2"  invoke2
  assert_equal "$FCN2" test-triggers/hello2
  refute [ "$ENAB2" == true ]
  assert_equal "$CRON2" "30 * * * *"
  assert_equal "$BODY2" null
}

@test "'triggers list' with --function flag is selective" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  run $DOCTL sls trig list --function test-triggers/hello1
  assert_success
  assert_output -p invoke1
  refute_output -p invoke2  
}

@test "undeploying a function also undeploys its trigger" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  run $DOCTL sls undeploy test-triggers/hello2
  assert_success
  run $DOCTL sls trig list
  assert_success
  assert_output -p invoke1
  refute_output -p invoke2  
}

@test "a deployed trigger fires its function more or less on time" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  sleep 60
  run bash -c "$DOCTL sls actv get --last --function test-triggers/hello1 | jq -r .logs[0]"
  assert_success
  assert_output -p "Hello tester!"
}

@test "a trigger can be undeployed without undeploying its function" {
  if [ -n "$NO_TRIGGERS" ]; then
    skip "skipping triggers test"
  fi
  run $DOCTL sls undeploy --triggers invoke1
  assert_success
  run $DOCTL sls trig list
  assert_success
  refute_output -p invoke1
  run $DOCTL sls fn list
  assert_success
  assert_output -p test-triggers/hello1
}