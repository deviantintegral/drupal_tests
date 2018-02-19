#!/bin/bash -ex

# CI test.sh hook implementation.

export SIMPLETEST_BASE_URL="http://localhost"
export SIMPLETEST_DB="sqlite://localhost//tmp/drupal.sqlite"
export BROWSERTEST_OUTPUT_DIRECTORY="/var/www/html/sites/simpletest"

# This is the command used by the base image to serve Drupal.
apache2-foreground&

robo override:phpunit-config $1

sudo -E -u www-data vendor/bin/phpunit -c core --group $1 --debug --verbose --log-junit artifacts/phpunit/phpunit.xml
