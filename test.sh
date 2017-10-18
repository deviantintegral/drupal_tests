#!/bin/bash -ex

# Test first manually specifying a branch
git init test_this_branch
cd test_this_branch
../setup.sh $1
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
../setup.sh
set +e
egrep -r '(my_module|MyModule)' * .circleci .gitignore
CHECK=$?
if [ $CHECK -eq 0 ]
then
  exit 1
fi
set -e

echo 'All tests have passed.'
