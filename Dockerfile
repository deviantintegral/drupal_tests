FROM drupal:8.5-rc-apache

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
# @TODO replace the following URL by http://robo.li/robo.phar when the Robo team fixes it.
RUN wget https://github.com/consolidation/Robo/releases/download/1.2.1/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# php-dom and bcmath dependencies
RUN apt-get install -y libxslt-dev
RUN docker-php-ext-install bcmath xsl

RUN apt-get install -y mariadb-client

RUN composer global require hirak/prestissimo

COPY hooks/* /var/www/html/

COPY drupal.sql.gz /var/www
COPY settings.php /var/www
RUN mkdir -p /var/www/html/sites/default/files/config_yt3arM1I65-zRJQc52H_nu_xyV-c4YyQ86uwM1E3JBCvD3CXL38O8JqAxqnWWj8rHRiigYrj0w/sync

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for phantomjs containers.
EXPOSE 80
