#!/bin/bash -ex

# Jenkins test-js.sh hook implementation.
#
# Runs Behat tests.

if [ ! -f dependencies_updated ]
then
  ./update-dependencies.sh $1
fi

# This is the command used by the base image to serve Drupal.
apache2-foreground&

# Wait for the mariadb container to come up.
while ! mysqladmin ping -h127.0.0.1; do sleep 1; done

robo setup:drupal || true

chown -R www-data:www-data /var/www/html/sites/default/files

vendor/bin/behat -v -c $(pwd)/modules/$1/tests/src/Behat/behat.yml
