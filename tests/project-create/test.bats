load ../test_setup.bash

# This test does not use our standard package naming convention and will overwrite the package 'sample'
teardown_file() {
  delete_package "sample"
}

function test_one() {
  rm -fr $BATS_TEST_DIRNAME/hello
  $DOCTL sbx init $BATS_TEST_DIRNAME/hello -l$1 >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    echo "Failed to create for language $1" >&2
    exit 1
  fi
  $DOCTL sbx deploy $BATS_TEST_DIRNAME/hello >/dev/null 2>&1
  if [ "$?" != "0" ]; then
    echo "Failed to deploy for language $1" >&2
    exit 1
  fi
  RESULT=$($DOCTL sbx fn invoke sample/hello 2>&1)
  if [[ "$RESULT" != *"Hello stranger"* ]]; then
    echo "Failed to invoke for language $1" >&2
    echo "Actual result: $RESULT" >&2
    exit 1
  fi
  echo "Successful test for language $1"
}

@test "Test project creation for javascript" {
  run test_one javascript
  assert_output "Successful test for language javascript"
}

@test "Test project creation for go" {
  run test_one go
  assert_output "Successful test for language go"
}

@test "Test project creation for php" {
  run test_one php
  assert_output "Successful test for language php"
}

@test "Test project creation for python" {
  run test_one python
  assert_output "Successful test for language python"
}
