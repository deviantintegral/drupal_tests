#!/bin/bash -ex

if [ -z $1 ]
then
  echo "Usage: ./export-drupal-db.sh <container tag or id>"
  exit 1
fi

docker network create drupal_tests || true
docker run -d --network drupal_tests -e MYSQL_ALLOW_EMPTY_PASSWORD=1 --name mariadb-host mariadb:10.3
docker run --network drupal_tests --name drupal-tests-export $1 /var/www/html/install-export.sh
docker cp drupal-tests-export:/var/www/drupal.sql.gz .
docker cp drupal-tests-export:/var/www/settings.php .
docker rm -f mariadb-host
docker rm -f drupal-tests-export
docker network rm drupal_tests
