load ../test_setup.bash

setup_file() {
	rm -rf $BATS_TEST_DIRNAME/test-project/*
	cp -r $BATS_TEST_DIRNAME/test-resources/example/* $BATS_TEST_DIRNAME/test-project
	$DOCTL sbx deploy $BATS_TEST_DIRNAME/test-project
}

teardown_file() {
	rm -rf $BATS_TEST_DIRNAME/test-project/*
	delete_package "incremental"
}

patch_project () {
	patch -p1 -d $BATS_TEST_DIRNAME/test-project < $BATS_TEST_DIRNAME/test-resources/$1.patch
}

@test "deploy project incrementally with no changes" {
	run $DOCTL sbx deploy $BATS_TEST_DIRNAME/test-project --incremental
	assert_success
	assert_line "Skipped 5 unchanged actions"
}

@test "deploy project incrementally with action changes" {
	patch_project "change-actions"

	run $DOCTL sbx deploy $BATS_TEST_DIRNAME/test-project --incremental
	assert_success
	assert_line "Skipped 3 unchanged actions"
	assert_line "  - incremental/action3"
	assert_line "  - incremental/action4"
}
