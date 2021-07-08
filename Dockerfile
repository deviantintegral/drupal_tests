# from https://www.drupal.org/docs/8/system-requirements/drupal-8-php-requirements
FROM php:7.4-apache-buster

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
		--with-freetype \
		--with-jpeg=/usr \
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

# Install Drupal.
WORKDIR /var/www

RUN rm -rf html
ARG DRUPAL_VERSION_CONSTRAINT="^8.9"
RUN composer create-project drupal/legacy-project:$DRUPAL_VERSION_CONSTRAINT html

WORKDIR /var/www/html

# The drupal/legacy-project is loose with version constraints. For instance the
# 8.9.16 tag requires drupal/core-recommended:^8.8. That can open you up to
# unexpectantly having drupal/core downgraded, which we want to avoid. We
# specifically require drupal/core-recommended and drupal/core-dev at ^8.9
# for this purpose.
RUN composer require --update-with-dependencies drupal/core-recommended:$DRUPAL_VERSION_CONSTRAINT drupal/core-dev:$DRUPAL_VERSION_CONSTRAINT wikimedia/composer-merge-plugin:^2.0 cweagans/composer-patches:^1.7.1
RUN chown -R www-data:www-data sites modules themes

# Cache currently used libraries to improve build times. We need to force
# discarding changes as Drupal removes test code in /vendor.
RUN cp composer.json composer.json.original \
  && cp composer.lock composer.lock.original \
  && mv vendor vendor.original \
  && composer require --update-with-all-dependencies --dev \
      cweagans/composer-patches \
      behat/mink-extension:v2.2 \
      drupal/drupal-extension:^4.0 \
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
RUN mkdir -p /var/www/html/sites/default/files/config_8faoX4lvQ9283v0ooiL1iEshqPsvAJpCDEyiKvBVq_kAxWxJVwQFnFp8z5PAuuqyUHEYUfJD2Q/sync \
  && chown -Rv www-data /var/www/html/sites/default/files

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for Selenium containers.
EXPOSE 80
