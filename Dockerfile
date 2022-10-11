FROM php:8.1-apache-buster as production

# Set working directory
WORKDIR /var/www

ENV PHP_VERSION=8.1

# Install Doppler CLI
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg && \
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | apt-key add - && \
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | tee /etc/apt/sources.list.d/doppler-cli.list && \
    apt-get update && \
    apt-get -y install doppler

RUN apt install -y git htop wget

RUN docker-php-ext-configure opcache --enable-opcache
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Install MySQL PDO
RUN docker-php-ext-install pdo pdo_mysql

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install php extensions
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions mbstring \
		exif \
		gd \
		intl \
		mbstring \
		memcached \
		pcntl \
		pdo_pgsql \
		pgsql \
		redis \
		sockets \
		sqlite3 \
		xdebug \
		zip

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    unzip \
    git \
    curl \
    lua-zlib-dev \
    libmemcached-dev \
    nginx


# Install supervisor
RUN apt-get install -y supervisor

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Forward Apache logs to docker
RUN ln -sf /dev/stdout /var/log/apache2/access.log &&\
    ln -sf /dev/stdout /var/log/apache2/other_vhosts_access.log &&\
    ln -sf /dev/stderr /var/log/apache2/error.log

# Forward PHP logs to docker
RUN ln -sf /dev/stderr /var/log/php_errors.log

# Forward PHP-FPM logs to docker
RUN ln -sf /dev/stderr /var/log/php${PHP_VERSION}-fpm.log || true

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ls -lah

RUN cd /var/www/html && ./install_app.sh

CMD ["/usr/local/bin/start"]
