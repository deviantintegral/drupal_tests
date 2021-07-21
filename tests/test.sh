#!/bin/bash -ex

test_ci() {
  cd node

  ../setup.sh $1 | tee setup.log
  grep "$1" setup.log

  circleci config validate
  set +e
  egrep -r '(my_module|MyModule)' * .circleci .gitignore
  CHECK=$?
  if [ $CHECK -eq 0 ]
  then
    set -e
    exit 1
  fi
  set -e

  # This module fails CS jobs currently so this is more informational.
  if [ ! -z $1 ]
  then
    ($HOME/bin/circleci local execute --job run-code-sniffer --env CIRCLE_PROJECT_REPONAME=node  | tee code-sniffer.log) || true
    # We need to skip colour codes
    egrep "Applying patches for .*drupal/coder" code-sniffer.log

    $HOME/bin/circleci local execute --job run-unit-kernel-tests --env CIRCLE_PROJECT_REPONAME=node

    $HOME/bin/circleci local execute --job run-functional-tests --env CIRCLE_PROJECT_REPONAME=node
    $HOME/bin/circleci local execute --job run-functional-js-tests --env CIRCLE_PROJECT_REPONAME=node

    $HOME/bin/circleci local execute --job run-behat-tests --env CIRCLE_PROJECT_REPONAME=node  | tee behat.log
    egrep "1 scenario \\(.*1 passed" behat.log

    # Test that a PHP FATAL error properly fails the job.
    git apply ../fixtures/behat-fail.patch

    # circleci doesn't bubble the exit code from behat :(
    $HOME/bin/circleci local execute --job run-behat-tests --env CIRCLE_PROJECT_REPONAME=node | tee behat.log
    grep -A9 'Behat tests failed' behat.log | tail -n 1 | grep '+ exit 1'

    git reset --hard HEAD
  fi
}

test_ci $1

echo 'All tests have passed.'
