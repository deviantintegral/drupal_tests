# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:7.3-apache-stretch
# TODO switch to buster once https://github.com/docker-library/php/issues/865 is resolved in a clean way (either in the PHP image or in PHP itself)

# install the PHP extensions we need
RUN set -eux; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype-dir=/usr \
		--with-jpeg-dir=/usr \
		--with-png-dir=/usr \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /var/www/html

RUN curl -L https://github.com/deviantintegral/drupal-update-client/releases/download/0.1.1/duc.phar -o /usr/local/bin/duc && \
  chmod +x /usr/local/bin/duc

WORKDIR /var/www

RUN rm -rf html
RUN duc project:extract drupal 8.x && \
  mv drupal-* html

WORKDIR /var/www/html

RUN chown -R www-data:www-data sites modules themes

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
RUN PHP_EXTENSION_DIR=$(php -r 'echo ini_get("extension_dir");') && \
  echo "zend_extension=$PHP_EXTENSION_DIR/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini

# We use imagemagick to support behat screenshots
RUN apt-get install -y imagemagick libmagickwand-dev
RUN pecl install imagick
RUN PHP_EXTENSION_DIR=$(php -r 'echo ini_get("extension_dir");') && \
  echo "extension=$PHP_EXTENSION_DIR/imagick.so" > /usr/local/etc/php/conf.d/imagick.ini

# unzip is recommended for composer over the zip extension
RUN apt-get install -y unzip

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
      "behat/mink-selenium2-driver:1.4.x-dev as 1.3.x-dev" \
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

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for phantomjs containers.
EXPOSE 80
