FROM drupal:8.6-apache

RUN apt-get update

# Install Git and wget.
RUN apt-get install git wget -y

# sudo is used to run tests as www-data.
RUN apt-get install -y sudo
RUN apt-get install -y sqlite3
RUN apt-get install -y vim
RUN apt-get install -y fontconfig

# xdebug isn't available as a prebuilt extension in the parent image.
RUN pecl install xdebug
RUN echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so' > /usr/local/etc/php/conf.d/xdebug.ini

# We use imagemagick to support behat screenshots
RUN apt-get install -y imagemagick libmagickwand-dev
RUN pecl install imagick
RUN echo 'extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/imagick.so' > /usr/local/etc/php/conf.d/imagick.ini

# Install composer.
COPY install-composer.sh /usr/local/bin/
RUN install-composer.sh

# Install Robo CI.
RUN wget https://robo.li/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# php-dom and bcmath dependencies
RUN apt-get install -y libxslt-dev
RUN docker-php-ext-install bcmath xsl

RUN apt-get install -y mariadb-client

RUN composer global require hirak/prestissimo

# Cache currently used libraries to improve build times. We need to force
# discarding changes as Drupal removes test code in /vendor.
RUN cd /var/www/html \
  && cp composer.json composer.json.original \
  && cp composer.lock composer.lock.original \
  && mv vendor vendor.original \
  && composer require --update-with-all-dependencies --dev \
      cweagans/composer-patches \
      behat/mink-selenium2-driver:1.3.x-dev \
      behat/mink-extension:v2.2 \
      drupal/coder:8.2.* \
      drupal/drupal-extension:master-dev \
      bex/behat-screenshot \
      phpmd/phpmd \
      phpmetrics/phpmetrics \
  && rm -rf vendor \
  && mv composer.json.original composer.json \
  && mv composer.lock.original composer.lock \
  && mv vendor.original vendor

COPY hooks/* /var/www/html/

# Commit our preinstalled Drupal database for faster Behat tests.
COPY drupal.sql.gz /var/www
COPY settings.php /var/www
RUN mkdir -p /var/www/html/sites/default/files/config_yt3arM1I65-zRJQc52H_nu_xyV-c4YyQ86uwM1E3JBCvD3CXL38O8JqAxqnWWj8rHRiigYrj0w/sync \
  && chown -Rv www-data /var/www/html/sites/default/files

# Patch Drupal to avoid a bug where behat failures show as passes.
# https://www.drupal.org/project/drupal/issues/2927012#comment-12467957
RUN cd /var/www/html \
  && curl https://www.drupal.org/files/issues/2927012.22-log-error-exit-code.patch | patch -p1

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for phantomjs containers.
EXPOSE 80
