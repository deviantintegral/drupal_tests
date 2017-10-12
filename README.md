# Drupal Testing Container

A Docker container and template for testing individual Drupal modules with:

* Unit and Kernel tests
* Behat tests
* Code standards
* Code coverage

If you want to test a whole Drupal site, and not an individual module, see
[d8cidemo](https://github.com/juampynr/d8cidemo).

## Features

* A Dockerfile extending the
  [official Drupal image](https://hub.docker.com/_/drupal/) to support
  Composer, Robo, and code coverage reports.
* Templates for a jobs running with CircleCI. 
* Most of the logic is in shell scripts and Robo commands, making it easy to
  run under a different CI tool.

## Getting started with CircleCI

1. Copy the `templates/circleci-2.0` directory to your module repository as
  `.circleci`.
1. Follow the steps at the top of the file.
1. To override a given hook, copy it to your `.circleci` directory. Then, in
   the run step, copy the script to the root of the project. For example, if
   you need to override `hooks/code-sniffer.sh`, the `run` step for the
   `code_sniffer` section would become:
   ```yaml
    - run:
     working_directory: /var/www/html
     command: |
       cp ./modules/$CIRCLE_PROJECT_REPONAME/.circleci/code-sniffer.sh /var/www/html
       ./code-sniffer.sh $CIRCLE_PROJECT_REPONAME
    ```
1. Connect your repository to Circle. At this point, all jobs should run,
   though no tests are actually being executed.

## Getting started with tests

1. Copy all of the files and directories from `templates/module` to the root of
   your new module.
1. Edit `phpunit.core.xml.dist` and set the whitelist paths for coverage
   reports, replacing `my_module` with your module name.
1. In `tests/src/Behat`, replace `my_module` and `MyModule` with your module name.
1. In your module's directory, include the required development dependencies:
   ```sh
   $ composer require --dev --no-update \
       behat/mink-selenium2-driver \
       drupal/coder \
       drupal/drupal-extension \
       bex/behat-screenshot \
       phpmd/phpmd \
       phpmetrics/phpmetrics
   ```
1. Start writing tests!

Unit, Kernel, Functional, and FunctionalJavascript tests all follow the same
directory structure as with Drupal contributed modules. If the Drupal testbot
could run your tests, this container should too.

Tests are executed using `run-tests.sh`. Make sure each test class has a proper
`@group` annotation, and that base classes do not have one. Likewise, make sure
that each test is in the proper namespace. If a Unit test is in the Kernel
namespace, things will break in hard-to-debug ways.

FunctionalJavascript tests are not yet supported as we use Behat for those
types of tests.

### Behat tests

Behat tests do not run on drupal.org, but we store them in a similar manner.
Most Behat implementations are testing sites, and not modules, so their docs
suggesting tests go in `sites/default/behat` don't apply. Instead, place tests
in `tests/src/Behat`, so that you end up with:

* `tests/src/Behat`
  * `behat.yml`
  * `features/`
    * `my_module_settings.feature`
    * `bootstrap/`
      * `MyModuleFeatureContext.php`

Behat can be buggy when using relative paths. To run your scenarios locally,
run from the Drupal root directory with an absolute path to your configuration.

```
$ vendor/bin/behat -v -c $(pwd)/modules/my_module/tests/src/Behat/behat.yml
```

## Overriding PHPUnit configuration

The `phpunit.core.xml.dist` configuration file is copied to Drupal's `core`
directory before running tests. Feel free to edit this file in each module as
needed.

## Applying patches

Sometimes, a module needs to apply patches to Drupal or another dependency to
work correctly. For example, out of the box we patch Coder to not throw errors
on Markdown files. To add or remove additional patches, edit `patches.json`
using the same format as
[composer-patches](https://github.com/cweagans/composer-patches).

## Testing against a new version of Drupal

The Docker container builds against the stable branch of Drupal core, such as
8.3.x and not a specific release like 8.3.2. This helps ensure tests always run
with the latest security patches. If you need to reproduce a build, see your
build logs for the specific image that was used:

```
Status: Downloaded newer image for andrewberry/drupal_tests:0.0.3
  using image andrewberry/drupal_tests@sha256:f65f0915e72922ac8db1545a76f6821e3c3ab54256709a2e263069cf8fb0d4e2
```

When a new minor version of Drupal is released:

1. Update the `Dockerfile` to point to a new release, such as
   `FROM drupal:8.4-apache`.
1. Build the container locally with `docker build -t drupal-8.4-test .`.
1. In a module locally, update `.circleci/config.yml` to with
   `-image: drupal-8.4-test`.
1. Test locally with `circleci build --job run-unit-kernel-tests` and so on for
   each job.
1. Submit a pull request to this repository.
1. After merging and when Docker hub has built a new tag, update your
   `config.yml` to point to it.
