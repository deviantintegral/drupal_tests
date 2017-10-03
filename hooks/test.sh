#!/bin/bash -ex

# Jenkins test.sh hook implementation.

export SIMPLETEST_BASE_URL="http://localhost"
export SIMPLETEST_DB="sqlite://localhost//tmp/drupal.sqlite"
export BROWSERTEST_OUTPUT_DIRECTORY="/var/www/html/sites/simpletest"

# This is the command used by the base image to serve Drupal.
apache2-foreground&

robo setup:skeleton
robo add:modules $repositoryName

robo update:dependencies

robo override:phpunit-config $repositoryName

sudo -E -u www-data robo setup:drupal
# sudo -u www-data robo test $repositoryName
sudo -u www-data mkdir /tmp/phpunit
sudo -u www-data php core/scripts/run-tests.sh --concurrency 31 --module $repositoryName --verbose --xml /tmp/phpunit/ --sqlite /tmp/drupal-tests.sqlite
