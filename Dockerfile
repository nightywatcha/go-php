FROM php:7.4.2-fpm as go-php
RUN apt-get -q update && apt-get -q install -y \
        git \
        unzip \
        zlib1g-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        jpegoptim \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) mysqli gettext exif gd \
    && printf "\n" | pecl install -o -f redis \
    && docker-php-ext-enable redis \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require hirak/prestissimo --no-plugins --no-scripts --no-progress

FROM go-php as go-dev

COPY ./php-extra.ini /usr/local/etc/php/conf.d/docker-php-extra.ini

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get -q update && \
    apt-get -q install -y nodejs

#Xdebug for debugging
RUN pecl install xdebug && docker-php-ext-enable xdebug

# XHProf
RUN apt-get install -y graphviz \
   && curl -L -o /tmp/xhprof.zip "https://github.com/tideways/php-xhprof-extension/archive/v5.0.2.zip" \
   && cd /tmp/ \
   && unzip xhprof.zip \
   && cd php-xhprof-extension-5.0.2 \
   && phpize \
   && ./configure \
   && make \
   && make install \
   && rm /tmp/xhprof.zip

RUN docker-php-ext-enable tideways_xhprof
RUN mkdir -p /opt/xhprof \
   && cd /opt/xhprof \
   && git clone https://github.com/phacility/xhprof.git \
   && chmod 777 xhprof/ -R

RUN apt-get update -y \
  && apt-get install -y \
    libxml2-dev \
  && apt-get clean -y \
  && docker-php-ext-install soap