FROM ruby:2.7.0-alpine3.10

RUN apk add --update \
            udev \
            ttf-freefont \
            chromium \
            chromium-chromedriver

RUN gem install selenium-webdriver
