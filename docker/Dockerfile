FROM ruby:2.7.0-alpine3.10

RUN apk add --update \
            udev \
            ttf-freefont \
            chromium \
            chromium-chromedriver

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata

RUN gem install selenium-webdriver
