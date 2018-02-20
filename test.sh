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
  circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-code-sniffer || true
  circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-unit-kernel-tests

  circleci.sh -e CIRCLE_PROJECT_REPONAME=node build --job run-behat-tests | tee behat.log
  # We need to skip colour codes
  egrep "1 scenario \\(.*1 passed" behat.log
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

git clone git@github.com:deviantintegral/drupal_tests_node_example.git node
cd node
git checkout 118b911

test_ci $1

echo 'All tests have passed.'
