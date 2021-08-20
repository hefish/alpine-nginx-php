FROM alpine:edge
LABEL Maintainer="hefish <hefish@qq.com>" \
      Description="Lightweight container with Nginx & PHP-FPM 7 based on Alpine Linux."

# Install packages
RUN echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main" > /etc/apk/repositories &&  \
    echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk --no-cache add php7-intl php7-openssl php7-dba php7-sqlite3 php7-pear php7-tokenizer php7-phpdbg  \
    php7-pecl-protobuf php7-gmp php7-phalcon php7-pecl-maxminddb \
    php7-pdo_mysql php7-sodium php7-pcntl php7-common php7-pecl-oauth php7-xsl php7-fpm \
    php7-pecl-mailparse php7-pecl-gmagick php7-mysqlnd php7-enchant \
    php7-pecl-uuid php7-pspell php7-pecl-ast php7-pecl-redis php7-snmp php7-tideways_xhprof \
    php7-fileinfo php7-mbstring php7-pecl-lzf php7-pecl-amqp \
    php7-pecl-yaml php7-pecl-timezonedb php7-pecl-psr php7-xmlrpc \
    php7-xmlreader php7-pdo_sqlite php7-exif php7-pecl-msgpack php7-opcache php7-ldap \
    php7-posix php7-session php7-gd php7-pecl-mongodb php7-gettext php7-pecl-couchbase \
    php7-json php7-xml php7-iconv php7-sysvshm php7-curl php7-shmop php7-odbc php7-pecl-uploadprogress \
    php7-phar php7-pdo_pgsql php7-imap php7-pecl-apcu php7-pdo_dblib php7-pgsql \
    php7-pdo_odbc php7-pecl-igbinary php7-pecl-xhprof mongo-php7-library php7-zip \
    php7-cgi php7-ctype php7-pecl-mcrypt php7-bcmath php7-calendar  php7 \
    php7-dom php7-sockets php7-pecl-zmq php7-pecl-event php7-pecl-vips php7-pecl-memcached \
    php7-brotli php7-soap php7-sysvmsg php7-pecl-ssh2 php7-ffi php7-embed php7-ftp php7-sysvsem \
    php7-pdo php7-static php7-bz2 php7-mysqli php7-pecl-xhprof-assets php7-simplexml php7-xmlwriter \
    tzdata composer nginx supervisor curl &&  \
    mkdir -p /var/www/html &&  \
    mkdir -p /etc/supervisor/conf.d &&  \
    addgroup -g 8000 www  && \
    adduser -u 8000 -H -G www -D www

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R www:www /run && \
  chown -R www:www /var/lib/nginx && \
  chown -R www:www /var/log/nginx && \
  chown -R www:www /var/log/php7

# Setup document root
RUN mkdir -p /var/www/html

# Make the document root a volume
VOLUME /var/www/html

# Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

