#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

USER_ID = ENV['KOT_USER_ID']
PSSWORD = ENV['KOT_PSSWORD']

require 'net/http'
require 'uri'
require 'date'
require 'selenium-webdriver'

ATTENDANCE = 'attendance'
LEAVING = 'leaving'
URL = 'https://s3.kingtime.jp/independent/recorder2/personal'

def make_driver
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,1080')

  # headless オプションでヘッドレスブラウザモード
  @driver = Selenium::WebDriver.for :chrome, options: options
end

def wait
  @wait ||= Selenium::WebDriver::Wait.new(:timeout => 3) # second
end

def login
  @driver.manage.timeouts.implicit_wait = 10
  @driver.navigate.to URL

  path = __FILE__
  if File.exists?(path) && File.ftype(path) == 'link'
    link = File.readlink(path)
    path = File.expand_path(link, File.dirname(path))
  end
  path = File.expand_path(File.dirname(path))

  wait.until { @driver.find_element(:id => "id").displayed? }

  login_id = @driver.find_element id: "id"
  login_id.send_keys USER_ID
  login_pass = @driver.find_element id: "password"
  login_pass.send_keys PSSWORD
  @driver.find_element(css: ".btn-control-inner").click
end

def button_click(button)
  sleep(3)
  button.click

  wait.until { @driver.find_element(id: "password").displayed? }
  login_pass = @driver.find_element id: "password"
  login_pass.send_keys PSSWORD
  login_button = @driver.find_element(css: ".btn-control-inner")
  login_button.click
  sleep 3
end

unless [ATTENDANCE, LEAVING].include? ARGV[0]
  puts "#{ATTENDANCE} or #{LEAVING}"
  exit
end

make_driver
login

wait.until { @driver.find_element(css: '.record-btn-message').displayed? }
buttons = @driver.find_elements(css: '.record-btn-message')
buttons.each do | button |
  button_click(button) if ATTENDANCE == ARGV[0] && button.text == "出勤"
  button_click(button) if LEAVING == ARGV[0] && button.text == "退勤"
end
