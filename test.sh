#!/bin/bash -ex

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
cd ..

# Finally, test using a real module!
git clone https://github.com/BurdaMagazinOrg/module-fb_instant_articles.git fb_instant_articles
cd fb_instant_articles
git checkout 66f934b196d6415f7f2dbad48d57653a7d02ee84
../setup.sh
sudo circleci build --job run-unit-kernel-tests
circleci build --job run-behat-tests
# We don't run the code coverage job because it's very slow
circleci build --job run-code-sniffer-tests
cd ..

echo 'All tests have passed.'
