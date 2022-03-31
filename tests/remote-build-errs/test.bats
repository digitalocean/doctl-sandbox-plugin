load ../test_setup.bash

teardown_file() {
  delete_package "test-remote-build-errs"
}

@test "deploy project with go source error" {
  run $DOCTL sbx deploy $BATS_TEST_DIRNAME --remote-build --include test-remote-build-errs/bad-src
  assert_failure
  assert_line -p "Output of failed build"
  assert_line -p "undefined: k"  
}

@test "deploy project with improper generated .include" {
  run $DOCTL sbx deploy $BATS_TEST_DIRNAME --remote-build --include test-remote-build-errs/bad-include
  assert_failure
  assert_line -p "Illegal use of '..' in an '.include' file"
}

@test "deploy project with misbehaving build script" {
  run $DOCTL sbx deploy $BATS_TEST_DIRNAME --remote-build --include test-remote-build-errs/bad-script
  assert_failure
  assert_line -p "Output of failed build"
  assert_line -p "'../../illegal': No such file or directory"
}