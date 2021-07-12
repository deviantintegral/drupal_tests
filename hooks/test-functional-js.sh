#!/bin/bash -ex

# CI test-functional-js.sh hook implementation.

export SIMPLETEST_BASE_URL="http://localhost"
export SIMPLETEST_DB="sqlite://localhost//tmp/drupal.sqlite"
export BROWSERTEST_OUTPUT_DIRECTORY="/var/www/html/sites/simpletest"
export MINK_DRIVER_ARGS_WEBDRIVER='["chrome", null, "http://localhost:4444/wd/hub"]'

if [ ! -f dependencies_updated ]
then
  ./update-dependencies.sh $1
fi

# This is the command used by the base image to serve Drupal.
apache2-foreground&

robo setup:artifacts-directory
robo setup:browser-output-directory
robo override:phpunit-config $1

sudo -E -u www-data vendor/bin/phpunit -c core --group $1 --testsuite functional-javascript --debug --verbose --log-junit artifacts/phpunit/phpunit.xml
