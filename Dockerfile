FROM php:8.1-apache-buster as production

# Install Doppler CLI
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg && \
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | apt-key add - && \
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | tee /etc/apt/sources.list.d/doppler-cli.list && \
    apt-get update && \
    apt-get -y install doppler git htop wget

RUN docker-php-ext-configure opcache --enable-opcache
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY xdebug.ini /etc/php/8.1/cli/conf.d/99-xdebug.ini

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions pdo_pgsql pgsql sqlite3 gd sockets exif zip mbstring xdebug intl pdo pdo_mysql

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite
