FROM ruby:3.2.0-alpine3.17

RUN gem install selenium-webdriver && \
    apk add --update \
    udev \
    ttf-freefont \
    chromium \
    chromium-chromedriver

RUN apk --no-cache add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata
