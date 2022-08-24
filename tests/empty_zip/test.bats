load ../test_setup.bash

setup_file() {
	export ZIPFILE=$BATS_TEST_DIRNAME/packages/default/action/__deployer__.zip
}

@test "deploying project with empty zip file should fail" {
	if [ -e $ZIPFILE]; then
    echo "$ZIPFILE should not exist"
		exit 1
	fi
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME -v
	assert_failure
	if [ -e $ZIPFILE]; then
    echo "$ZIPFILE should not exist"
		exit 1
	fi
	assert_output --partial "Action 'action' has no included files"
}
