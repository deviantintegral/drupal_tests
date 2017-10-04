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
