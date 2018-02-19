#!/bin/bash -ex

robo setup:skeleton
robo add:modules $1

robo add:behat-deps
robo add:coding-standards-deps
robo update:dependencies

# Touch a flag so we know dependencies have been set. Otherwise, there is no
# easy way to know this step needs to be done when running circleci locally since
# it does not support workflows.
touch dependencies_updated
