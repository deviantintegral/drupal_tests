#!/bin/bash -ex

robo setup:skeleton
robo add:modules $1

robo add:behat-deps
robo add:coding-standards-deps
robo update:dependencies
