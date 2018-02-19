#!/bin/bash -ex

git clone git@github.com:nodespark/elasticsearch_connector.git
cd elasticsearch_connector
git checkout 22ac399
../setup.sh $1
circleci -e CIRCLE_PROJECT_REPONAME=elasticsearch_connector build --job run-behat-tests

# Test first manually specifying a branch
git init test_this_branch
cd test_this_branch
composer init -n --name=example/test
../setup.sh $1
circleci config validate
set +e
egrep -r '(my_module|MyModule)' * .circleci .gitignore
CHECK=$?
if [ $CHECK -eq 0 ]
then
  exit 1
fi
set -e
cd ..

# Now test using this code to fetch the last tag
git init test_last_tag
cd test_last_tag
composer init -n --name=example/test
../setup.sh
circleci config validate
set +e
egrep -r '(my_module|MyModule)' * .circleci .gitignore
CHECK=$?
if [ $CHECK -eq 0 ]
then
  exit 1
fi
set -e

echo 'All tests have passed.'
