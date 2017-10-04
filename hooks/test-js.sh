#!/bin/bash -ex

# Jenkins test-js.sh hook implementation.
#
# Runs Behat tests.

# This is the command used by the base image to serve Drupal.
apache2-foreground&

robo add:behat-deps

robo add:modules $1

robo update:dependencies

robo setup:drupal || true

chown -R www-data:www-data /var/www/html/sites/default/files

vendor/bin/behat -v -c $(pwd)/modules/$1/tests/src/Behat/behat.yml
