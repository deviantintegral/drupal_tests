#!/bin/bash -ex

sudo apt-get update -y
sudo apt-get install php5-cli -y
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

sudo php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer

# There is a circleci CLI tool in the machine image, but it throws errors about
# missing files when running builds.
sudo curl -o /usr/local/bin/circleci.sh https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci && sudo chmod +x /usr/local/bin/circleci.sh

# Docker Hub can take 20 minutes to build and sometimes fails. Instead, we
# test against a locally built copy of the image when building this branch.
if [ ! -z $1 ]
then
  docker build -t $CI_SYSTEM-build .
fi

git clone git@github.com:deviantintegral/drupal_tests_node_example.git node
cd node
git checkout drupal-node-86

echo 'Test dependencies set up.'
