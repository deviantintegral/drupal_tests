#!/bin/bash -ex

# Jenkins test-js.sh hook implementation.
#
# Runs Behat tests.

if [ ! -f dependencies_updated ]
then
  ./update-dependencies.sh $1
fi

# This is the command used by the base image to serve Drupal. We redirect logs
# from stdout so they aren't intermingled with Behat's test output. The proper
# docker method for this would be to run Behat in a separate container, but
# this is tricky with Circle's docker executor.
# https://circleci.com/docs/2.0/executor-types/#machine-executor-overview
for i in /var/log/apache2/*.log
do
  rm -v $i
  touch $i
done
mkdir -p artifacts/logs
ln -v /var/log/apache2/*log artifacts/logs
apachectl start

# Wait for the mariadb container to come up.
while ! mysqladmin ping --silent -h127.0.0.1; do sleep 1; done

# Restore and update a previously installed Drupal site.
mv ../settings.php sites/default/
vendor/bin/drush sql-create -y
zcat ../drupal.sql.gz | vendor/bin/drush sqlc
vendor/bin/drush updatedb -y

set +e
vendor/bin/behat -v -c $(pwd)/modules/$1/tests/src/Behat/behat.yml

if [ $? -gt 0 ]
then
  echo 'Behat tests failed. The last 100 lines of the access log are:'
  tail -n 100 /var/log/apache2/access.log
  echo ''
  echo 'The last 100 lines of the error log are:'
  tail -n 100 /var/log/apache2/error.log
  exit 1
fi

# Restore -e in case we add more later.
set -e
