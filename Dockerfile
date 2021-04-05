FROM alpine:edge
LABEL Maintainer="hefish <hefish@qq.com>" \
      Description="Lightweight container with Nginx & PHP-FPM 7 based on Alpine Linux."

# Install packages
RUN echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main" > /etc/apk/repositories &&  \
    echo "http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && apk --no-cache add php7 php7-fpm php7-mysqli php7-json php7-openssl php7-curl \
    php7-zip php7-xml php7-simplexml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype \
    php7-session php7-mbstring php7-gd php7-pecl-imagick php7-pecl-memcached php7-pdo php7-pdo_mysql \
    php7-opcache nginx supervisor curl py3-setuptools &&  \
    mkdir -p /var/www/html &&  \
    mkdir -p /etc/supervisor/conf.d

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nogroup /run && \
  chown -R nobody:nogroup /var/lib/nginx && \
  chown -R nobody:nogroup /var/log/nginx && \
  chown -R nobody:nogroup /var/log/php7

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

