#!/bin/bash -ex

# Runs CodeSniffer checks on a Drupal module.

robo add:coding-standards-deps

robo add:modules $1

robo update:dependencies

# Install dependencies and configure phpcs
vendor/bin/phpcs --config-set installed_paths vendor/drupal/coder/coder_sniffer

# Check coding standards
vendor/bin/phpcs --standard=Drupal modules/$1
