FROM hyperf/hyperf:8.0-alpine-v3.13-swoole
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    APP_ENV=prod \
    SW_VERSION=${SW_VERSION:-"v4.6.7"} \
    #  install and remove building packages
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php8-dev php8-pear pkgconf re2c pcre-dev pcre2-dev zlib-dev libtool automake"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

COPY ./ext /opt/ext

# update
RUN set -ex \
    && apk update \
    # for swoole extension libaio linux-headers
    && apk add --no-cache libstdc++ openssl git bash \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev curl-dev \
    && ln -s /usr/bin/phpize8 /usr/local/bin/phpize \
    && ln -s /usr/bin/php-config8 /usr/local/bin/php-config \
    && php -v \
    && cd /opt/ext \
    && mkdir -p /tmp/xlswriter \
    && tar -xf /opt/ext/xlswriter.tgz -C /tmp/xlswriter --strip-components=1 \
    && rm /opt/ext/xlswriter.tgz \
    && cd /tmp/xlswriter \
    && phpize8 && ./configure --with-php-config=/usr/bin/php-config8 --enable-reader && make && make install \
    && echo "extension=xlswriter.so" > /etc/php8/conf.d/xlswriter.ini \
    # install composer
    && cp /opt/ext/composer.phar /tmp/composer.phar \
    && cd /tmp \
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
    && cd /etc/php8 \
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
