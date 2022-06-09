FROM hyperf/hyperf:7.4-alpine-v3.15-swoole
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    COMPOSER_VERSION=2.1.3 \
    APP_ENV=prod

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

COPY ./ext /opt/ext

# update
RUN set -ex \
    && apk update \
    # install igbinary extension
    && apk add --no-cache php7-pear php7-dev zlib-dev re2c gcc g++ make curl autoconf \
    && cp /usr/bin/phpize7 /usr/bin/phpize -f \
    && cd /opt/ext \
    && mkdir -p /tmp/igbinary \
    && tar -xf /opt/ext/igbinary-3.2.2.tgz -C /tmp/igbinary --strip-components=1 \
    && rm /opt/ext/igbinary-3.2.2.tgz \
    && cd /tmp/igbinary \
    && phpize && ./configure --with-php-config=/usr/bin/php-config7 --enable-reader && make && make install \
    && echo "extension=igbinary.so" > /etc/php7/conf.d/igbinary.ini \
    && mkdir -p /tmp/xlswriter \
    && tar -xf /opt/ext/xlswriter-1.5.1.tgz -C /tmp/xlswriter --strip-components=1 \
    && rm /opt/ext/xlswriter-1.5.1.tgz \
    && cd /tmp/xlswriter \
    && phpize && ./configure --with-php-config=/usr/bin/php-config7 --enable-reader && make && make install \
    && echo "extension=xlswriter.so" > /etc/php7/conf.d/xlswriter.ini \
    && mkdir -p /tmp/pcre2 \
    && tar -xf /opt/ext/pcre2-10.37.tar.gz -C /tmp/pcre2 --strip-components=1 \
    && rm /opt/ext/pcre2-10.37.tar.gz \
    && cd /tmp/pcre2 \
    && ./configure --prefix=/usr/local/pcre2 && make && make install \
    && ln -s /usr/local/pcre2 /usr/sbin/pcre2 \
#    && ln -s /usr/local/pcre2/include/pcre2.h /usr/include/pcre2.h \
    && mkdir -p /tmp/mongodb \
    && tar -xf /opt/ext/mongodb-1.10.0.tgz -C /tmp/mongodb --strip-components=1 \
    && rm /opt/ext/mongodb-1.10.0.tgz \
    && cd /tmp/mongodb \
    && phpize && ./configure --with-php-config=/usr/bin/php-config7 --enable-reader && make && make install \
    && echo "extension=mongodb.so" > /etc/php7/conf.d/mongodb.ini \
    # install composer
    && cp /opt/ext/composer.phar /tmp/composer.phar \
    && cd /tmp \
#    && wget https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && composer config -g secure-http false \
    && ls  ~/.composer/  \
    && cat  ~/.composer/auth.json  \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php7 \
    # - config PHP
    && { \
        echo "upload_max_filesize=100M"; \
        echo "post_max_size=108M"; \
        echo "memory_limit=1024M"; \
        echo "date.timezone=${TIMEZONE}"; \
    } | tee conf.d/99-overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"
