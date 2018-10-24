# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased] - YYYY-MM-DD

### Changed

* Updates to Drupal 8.6 #49
  * Selenium has been upgraded to 3.14.0
  * Full support for Functional Javascript tests
  * Fixes running all tests in the unit/kernel test job
  * `test-js.sh` has been renamed to `behat.sh`.
  * `test-functional.sh` and `test-functional-js.sh` hooks have been added.

## [0.3.4] - 2018-04-04

### Changed

* Update to Drupal 8.5 release #42
* Update drupal and robo versions.

### Fixed

* Fix mink-selenium version conflict with Drupal 8.5 dev requirement
* Fix composer-patches not triggering on first composer update #44

## [0.3.3] - 2018-02-28

### Fixed

* Increment the cache key version prefix to avoid issues with stale caches. #36

## [0.3.2] - 2018-02-27

### Fixed

* It turns out that caching `vendor` based only on `composer.json` is a very
  bad idea. Instead, only cache the literal Composer cache. #35

## [0.3.1] - 2018-02-23

### Fixed

* Certain types of PHP errors did not throw a failed exit code in Behat tests.
  [_drupal_log_error() returns a 0 exit code on errors](https://www.drupal.org/project/drupal/issues/2927012)
  has been applied to Drupal core until it's fixed upstream. [#33](https://github.com/deviantintegral/drupal_tests/pull/33)
* Fix version conflict with root composer-patches requirement [#34](https://github.com/deviantintegral/drupal_tests/pull/34)

## [0.3.0] - 2018-02-21

### Added

* A single job is now used to initialize composer, and it's results are used to
  seed all of the individual test jobs.
  [#26](https://github.com/deviantintegral/drupal_tests/pull/26/files)
* A `drupal.sql.gz` and `settings.php` file are included with a pre-installed
  Drupal database. See the Behat test script for how it's imported and used.

### Changed

* Drupal 8.5 is now used for tests [#24](https://github.com/deviantintegral/drupal_tests/pull/24)
* The container has been upgraded to PHP 7.2, which means PHPUnit 6 is now
  required.
* Phantom JS has now been removed. Use a container link instead. [#15](https://github.com/deviantintegral/drupal_tests/issues/15).
* HTTP logs are split form Behat logs.
* The Robo setup:drupal command now takes options instead of arguments.

### Fixed

* `setup.sh` now allows `master` to be used, properly mapping it to the
  `latest` Docker container build.

## [0.2.0] - 2018-01-09

### Added

* The code coverage job only runs if unit and kernel tests have passed first.

### Changed

* Chrome is now used for Behat tests instead of PhantomJS #13
* The Drupal extension version is now set to master-dev #11
* `behat/mink-extension` has been pinned to `v2.2` until
  [Fix Behat/MinkExtension#309 Firefox starts instead of Chrome #311](https://github.com/Behat/MinkExtension/pull/311)
  is included in a release.

### Fixed

* Improved handling of interrupted `setup.sh` downloads #17
* The Robo install URL has been fixed #16
* A missing dev dependency on composer-patches has been added #14

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

