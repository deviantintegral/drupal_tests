#!/bin/bash -ex

export SIMPLETEST_BASE_URL="http://localhost"
export SIMPLETEST_DB="sqlite://localhost//tmp/drupal.sqlite"
export BROWSERTEST_OUTPUT_DIRECTORY="/var/www/html/sites/simpletest"

robo add:modules $1

robo update:dependencies

robo override:phpunit-config $1

timeout 60m sudo -E -u www-data robo test:coverage $1 /var/www/html/sites || true
tar czf /var/www/html/sites/coverage.tar.gz -C /var/www/html/sites coverage-html coverage-xml
