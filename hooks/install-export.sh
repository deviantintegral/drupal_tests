#!/bin/bash

# Install Drupal, exporting the database and settings file.
robo setup:skeleton
COMPOSER_DISCARD_CHANGES=1 robo update:dependencies
robo setup:drupal --db-url=mysql://root@mariadb-host/drupal8
vendor/bin/drush sql-dump --result-file=../drupal.sql --gzip
mv sites/default/settings.php ../
