load "./node_modules/bats-support/load.bash"
load "./node_modules/bats-assert/load.bash"

if [ -z "$DOCTL" ]; then
  DOCTL=$PWD/../../doctl/builds/doctl
fi

# Utility function to clear our all package resources.
delete_package() {
	$DOCTL sbx undeploy $1 --packages
}

test_binary_action() {
	run $DOCTL sbx fn invoke $1 -f
	assert_success
	assert_output --partial '"status": "success"'
	assert_output --partial $2

	run $DOCTL sbx fn get $1
	assert_success
	assert_output --partial '"binary": true'
}
