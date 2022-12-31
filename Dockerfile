FROM php:8.1-apache-buster as production

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM xterm
ENV npm_config_loglevel warn
ENV npm_config_unsafe_perm true
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null
ENV CHROME_VERSION 90.0.4430.212
ENV FIREFOX_VERSION 88.0.1
# ENV CI=1
ENV CYPRESS_CACHE_FOLDER=/root/.cache/Cypress

RUN apt update && apt install -y \
    # Cypress dependencies
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb \
    # Extra dependencies
    fonts-liberation \
    libappindicator3-1 \
    xdg-utils \
    mplayer \
    apt-utils \
    wget

# Chrome
RUN wget -O /usr/src/google-chrome-stable_current_amd64.deb "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" && \
    dpkg -i /usr/src/google-chrome-stable_current_amd64.deb ; \
    apt-get install -f -y && \
    rm -f /usr/src/google-chrome-stable_current_amd64.deb

# Firefox
RUN wget --no-verbose -O /tmp/firefox.tar.bz2 "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2" \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
    && rm /tmp/firefox.tar.bz2 \
    && ln -fs /opt/firefox/firefox /usr/bin/firefox

# Install Doppler CLI
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg && \
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | apt-key add - && \
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | tee /etc/apt/sources.list.d/doppler-cli.list && \
    apt-get update && \
    apt-get -y install doppler git htop wget

# Needed for phantomjs
RUN apt-get install bzip2 libfontconfig -y
RUN mkdir /tmp/phantomjs \
    && curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
            | tar -xj --strip-components=1 -C /tmp/phantomjs \
    && cd /tmp/phantomjs \
    && mv bin/phantomjs /usr/local/bin \
    && chmod a+x /usr/local/bin/phantomjs

RUN docker-php-ext-configure opcache --enable-opcache
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY xdebug.ini /etc/php/8.1/cli/conf.d/99-xdebug.ini

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions pdo_pgsql pgsql gd sockets exif zip xdebug intl pdo pdo_mysql gmp pcntl
# RUN install-php-extensions sqlite3 mbstring # Already installed

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Node, NPM, Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt install -y nodejs && npm -g install yarn --unsafe-perm

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start
RUN a2enmod rewrite
