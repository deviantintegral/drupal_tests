#!/bin/bash -ex

test_ci() {
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
    (circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-code-sniffer | tee code-sniffer.log) || true
    # We need to skip colour codes
    egrep "Applying patches for .*drupal/coder" code-sniffer.log

    circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-unit-kernel-tests

    circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-behat-tests | tee behat.log
    egrep "1 scenario \\(.*1 passed" behat.log

    # Test that a PHP FATAL error properly fails the job.
    git apply ../fixtures/behat-fail.patch

    # circleci doesn't bubble the exit code from behat :(
    circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-behat-tests | tee behat.log
    grep -A9 'Behat tests failed' behat.log | tail -n 1 | grep '+ exit 1'

    git reset --hard HEAD
  fi
}

sudo apt-get update -y
sudo apt-get install php5-cli -y
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer

# There is a circleci CLI tool in the machine image, but it throws errors about
# missing files when running builds.
sudo curl -o /usr/local/bin/circleci.sh https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci && sudo chmod +x /usr/local/bin/circleci.sh

# Docker Hub can take 20 minutes to build and sometimes fails. Instead, we
# test against a locally built copy of the image when building this branch.
if [ ! -z $1 ]
then
  docker build -t $CI_SYSTEM-build .
fi

git clone git@github.com:deviantintegral/drupal_tests_node_example.git node
cd node
git checkout drupal-node-86

test_ci $1

echo 'All tests have passed.'
