FROM drupal:latest

RUN apt-get update

# sudo is used to run tests as www-data.
RUN apt-get install -y sudo
RUN apt-get install -y sqlite3
RUN apt-get install -y vim

# xdebug isn't available as a prebuilt extension in the parent image.
RUN pecl install xdebug
RUN echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so' > /usr/local/etc/php/conf.d/xdebug.ini
