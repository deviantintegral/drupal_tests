#!/bin/bash -ex

sudo apt update -y
sudo apt install php php-cli php-common php-json php-curl -y
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
curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | DESTDIR=$HOME/bin bash

# Docker Hub can take 20 minutes to build and sometimes fails. Instead, we
# test against a locally built copy of the image when building this branch.
if [ ! -z $1 ]
then
  docker build -t $CI_SYSTEM-build .
fi

git clone git@github.com:deviantintegral/drupal_tests_node_example.git node
cd node
git checkout drupal-node-87

echo 'Test dependencies set up.'
