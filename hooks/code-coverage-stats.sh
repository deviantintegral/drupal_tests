#!/bin/bash -ex

export SIMPLETEST_BASE_URL="http://localhost"
export SIMPLETEST_DB="sqlite://localhost//tmp/drupal.sqlite"
export BROWSERTEST_OUTPUT_DIRECTORY="/var/www/html/sites/simpletest"

robo add:modules $repositoryName

robo update:dependencies

robo override:phpunit-config $repositoryName

timeout 60m sudo -E -u www-data robo test:coverage $repositoryName /var/www/html/sites || true
tar czf /var/www/html/sites/coverage.tar.gz -C /var/www/html/sites coverage-html coverage-xml
