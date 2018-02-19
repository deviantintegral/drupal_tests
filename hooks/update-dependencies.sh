#!/bin/bash -ex

robo setup:skeleton
robo add:modules $1

robo update:dependencies
robo add:behat-deps
