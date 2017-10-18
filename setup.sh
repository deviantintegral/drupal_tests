#!/bin/bash -e

MODULE=$(basename $(pwd))
MODULE_CC=$(echo $MODULE | perl -pe 's/(^|_)(\w)/\U$2/g')

echo "Using $MODULE as the module name and $MODULE_CC as the CamelCase version."

# Get the latest tag. We have to use the v3 API as GraphQL doens't support
# anonymous access.
# It is currently sorted in reverse chronological order. To always be correct,
# we should probably query each tag and then sort, but we want to maintain
# anonymous support and that could easily hit the API limit.
if [ -z "$1" ]
then
  TAG=$(curl -s https://api.github.com/repos/deviantintegral/drupal_tests/tags | grep name | head -n 1 | awk -F\" '{print $4}')
else
  TAG=$1
fi

echo "Using $TAG as the container version."

# Download the CircleCI configuration.
mkdir -p .circleci
curl -s -L https://github.com/deviantintegral/drupal_tests/raw/$TAG/templates/circleci-2.0/config.yml > .circleci/config.yml

# Update the container version in the config file.
perl -i -pe "s/andrewberry\/drupal_tests:latest/andrewberry\/drupal_tests:$TAG/g" .circleci/config.yml
perl -i -pe "s/my_module/$MODULE/g" .circleci/config.yml

# Set up phpunit with code coverage for this module.
curl -s -L -q -OJ https://github.com/deviantintegral/drupal_tests/raw/$TAG/templates/module/phpunit.core.xml.dist
perl -i -pe "s/my_module/$MODULE/g" phpunit.core.xml.dist

# Download and set up the Behat testing configuration.
mkdir -p "tests/src/Behat/features/bootstrap"

curl -s -L -q https://github.com/deviantintegral/drupal_tests/raw/$TAG/templates/module/tests/src/Behat/behat.yml > tests/src/Behat/behat.yml
curl -s -L -q https://github.com/deviantintegral/drupal_tests/raw/$TAG/templates/module/tests/src/Behat/example.behat.local.yml > tests/src/Behat/example.behat.local.yml
curl -s -L -q https://github.com/deviantintegral/drupal_tests/raw/$TAG/templates/module/tests/src/Behat/features/bootstrap/MyModuleFeatureContext.php > tests/src/Behat/features/bootstrap/${MODULE_CC}FeatureContext.php

perl -i -pe "s/my_module/$MODULE/g" tests/src/Behat/features/bootstrap/${MODULE_CC}FeatureContext.php tests/src/Behat/example.behat.local.yml tests/src/Behat/behat.yml
perl -i -pe "s/MyModule/$MODULE_CC/g" tests/src/Behat/features/bootstrap/${MODULE_CC}FeatureContext.php tests/src/Behat/example.behat.local.yml tests/src/Behat/behat.yml

touch .gitignore
if [ ! $(grep behat.local.yml .gitignore) ]
then
  echo 'tests/src/Behat/behat.local.yml' >> .gitignore
fi

composer require --dev --no-update \
    behat/mink-selenium2-driver \
    drupal/coder \
    drupal/drupal-extension \
    bex/behat-screenshot \
    phpmd/phpmd \
    phpmetrics/phpmetrics

echo 'Setup complete. You are now ready to test with CircleCI!'
