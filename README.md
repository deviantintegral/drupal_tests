# Drupal Testing Container

A Docker container and template for testing individual Drupal modules with:

* Unit and Kernel tests
* Behat tests
* Code standards
* Code coverage

If you want to test a whole Drupal site, and not an individual module, see
[d8cidemo](https://github.com/juampynr/d8cidemo).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Features](#features)
- [Getting started with CircleCI](#getting-started-with-circleci)
- [Getting started with tests](#getting-started-with-tests)
  - [Behat tests](#behat-tests)
  - [Debugging Behat tests](#debugging-behat-tests)
- [Overriding PHPUnit configuration](#overriding-phpunit-configuration)
- [Applying patches](#applying-patches)
- [Updating templates in modules](#updating-templates-in-modules)
- [Testing against a new version of Drupal](#testing-against-a-new-version-of-drupal)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Features

* A Dockerfile extending the
  [official Drupal image](https://hub.docker.com/_/drupal/) to support
  Composer, Robo, and code coverage reports.
* Templates for a jobs running with CircleCI. 
* Most of the logic is in shell scripts and Robo commands, making it easy to
  run under a different CI tool.

## Getting started with CircleCI

1. `cd` to the directory with your Drupal module. Make sure it's a git
   repository first!
1. `bash -c "$(curl -fsSL https://github.com/deviantintegral/drupal_tests/raw/master/setup.sh)"`
1. Review and commit the new files.
1. Connect the repository to CircleCI.
1. Add a `COMPOSER_AUTH` environment variable to Circle if you are using
   private repositories.
1. Push a branch . At this point, all jobs should run, though no tests are
   actually being executed.
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

## Getting started with tests

If you ran `setup.sh` these steps have been done automatically.

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

### Debugging Behat tests

Behat is configured to use Selenium and Chrome along with a VNC server. If your
CI provider allows SSH access to containers, you can forward ports to inspect
the build.

In CircleCI, first rebuild the Behat job with SSH. Once you have the SSH command
to run, forward ports as needed. For example, to point port `8080` on your local
machine to Apache, and port `5900` to the VNC server, run:

`$ <ssh command copied from the job> -L8080:localhost:80 -L5900:localhost:80`

The container's site will now be available at `http://localhost:8080`. To log
in to Drupal, use `drush user-login` from SSH inside of the container.

```sh
$ cd /var/www/html
$ vendor/bin/drush -l localhost:8080 user-login
```

Click the link that is printed out and you should be logged in as
administrator.

For VNC, connect to `localhost:5900` with the VNC client of your choice. The
VNC password is `secret`. If you manually run Behat tests from within the
SSH connection, you should see Chrome start and tests execute.

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

## Updating templates in modules

To update to the latest release of this template, simply run `setup.sh` again.
Be sure to review for any customizations you may want to preserve. For example:

```sh
$ git checkout -b update-circleci
$ curl -L https://github.com/deviantintegral/drupal_tests/raw/master/setup.sh | bash
$ git add -p # Add all changes you want to make.
$ git checkout -p # Remove any changes you don't want to make.
$ git status # Check for any newly added files.
$ git commit
```

In terms of semantic versioning, we consider the Docker image to be our
"public" API. In other words, we will bump the major version (or minor pre-1.0)
if updating the container also requires changes to the template files in a
given module.

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
