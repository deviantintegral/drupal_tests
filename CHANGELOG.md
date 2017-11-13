# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2017-11-08

### Added

* Automated setup script for new projects.
* Support for running tests under Drupal 8.4.
* Support for the following jobs and reports:
  * Drupal Unit, Kernel, and Functional tests.
  * Behat tests with screenshots of each step.
  * Code standards and code quality reports with phpcs, phpmd, and phpmetrics.
  * Code coverage reports for Unit and Kernel tests.
* Linked containers for mariadb and phantomjs.
* Support for test hook overrides.
* Support for applying patches with Composer via `patches.json`.

