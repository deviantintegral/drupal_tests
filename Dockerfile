FROM drupal:8.4-apache

RUN apt-get update

# Install Git and wget.
RUN apt-get install git wget -y

# This URL is sometimes 403'ing so we pull it into the image.
# This will be removed in favour of a separate container.
RUN apt-get install -y bzip2 libfontconfig
RUN cd '/opt' && curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar xjvf -
RUN ln -s /opt/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin

# sudo is used to run tests as www-data.
RUN apt-get install -y sudo
RUN apt-get install -y sqlite3
RUN apt-get install -y vim
RUN apt-get install -y fontconfig

# xdebug isn't available as a prebuilt extension in the parent image.
RUN pecl install xdebug
RUN echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20160303/xdebug.so' > /usr/local/etc/php/conf.d/xdebug.ini

# We use imagemagick to support behat screenshots
RUN apt-get install -y imagemagick libmagickwand-dev
RUN pecl install imagick
RUN echo 'extension=/usr/local/lib/php/extensions/no-debug-non-zts-20160303/imagick.so' > /usr/local/etc/php/conf.d/imagick.ini

# Install composer.
COPY install-composer.sh /usr/local/bin/
RUN install-composer.sh

# Install Robo CI.
# @TODO replace the following URL by http://robo.li/robo.phar when the Robo team fixes it.
RUN wget https://github.com/consolidation/Robo/releases/download/1.1.5/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# php-dom and bcmath dependencies
RUN apt-get install -y libxslt-dev
RUN docker-php-ext-install bcmath xsl

RUN apt-get install -y mariadb-client

COPY hooks/* /var/www/html/

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for phantomjs containers.
EXPOSE 80
