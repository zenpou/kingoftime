#!/usr/bin/env ruby

# 定数で設定
USER_ID = ENV['KOT_USER_ID']
PSSWORD = ENV['KOT_PSSWORD']
# 出社時間
IN_TIME = ENV['IN_TIME']
# 退社時間
OUT_TIME = ENV['OUT_TIME']
# 30分以上遅れた時のデフォルトメッセージ
OUT_MESSAGE = ENV['OUT_MESSAGE']

require 'net/http'
require 'uri'
require 'yaml'
require 'optparse'
require 'date'
require 'selenium-webdriver'

URL = "https://s3.kingtime.jp/admin"

# time round
ROUND = 15

def time_to_min(time)
  hour, min = time.split(":")
  hour.to_i * 60 + min.to_i
end

def default_outmessage
  if time_to_min(@leave_time) - time_to_min(OUT_TIME) > 30
    return OUT_MESSAGE
  end
  return nil
end

def option_parse
  opt = OptionParser.new
  @in_time = IN_TIME
  @leave_time = leave_time_make

  @date_at = Date.today.strftime("%Y-%m-%d")
  @in_message = ""
  @leave_message = default_outmessage
  opt.on("-d #{@date_at}", "--date", "日付を指定する"){|v| @date_at = v}
  opt.on("-i #{@in_time}", "--intime", "時間（出勤）を指定する"){|v| @in_time = v}
  opt.on("-l #{@leave_time}", "--leavetime", "時間（退勤）を指定する"){|v| @leave_time = v}
  opt.on("-m #{@in_message}", "--in-biko", "備考（出勤）を指定する"){|v| @in_message = v}
  opt.on("-b #{@leave_message}", "--out-biko", "備考（退勤）を指定する"){|v| @leave_message = v}
  opt.banner = "note: king of timeの勤怠情報を登録します\n\nOptions:\n"

  opt.parse!(ARGV)
  @date_at = Date.parse(@date_at)
end

def leave_time_make
  now = Time.now
  min = (now.min / ROUND).to_i * ROUND
  "#{"%02d" % now.hour}:#{"%02d" % min}"
end


def login
  @driver.manage.timeouts.implicit_wait = 30
  @driver.navigate.to URL

  path = __FILE__
  if File.exists?(path) && File.ftype(path) == 'link'
    link = File.readlink(path)
    path = File.expand_path(link, File.dirname(path))
  end
  path = File.expand_path(File.dirname(path))

  wait.until { @driver.find_element(:id => "login_id").displayed? }

  login_id = @driver.find_element id: "login_id"
  login_id.send_keys USER_ID
  login_pass = @driver.find_element id: "login_password"
  login_pass.send_keys PSSWORD
  @driver.find_element(id: "login_button").click
  wait.until { @driver.find_element(class: "htBlock-autoNewLineTable").displayed? }
end

def tr_find
  date_str = "#{@date_at.strftime("%m/%d")}（#{"日月火水木金土"[@date_at.wday]}）"

  elements = @driver.find_elements(class: "htBlock-scrollTable_day")
  target = nil
  elements.each do | element |
    if element.text =~ /#{date_str}/
      target = element
      break
    end
  end
  if target
    return target.find_element(xpath: "..")
  end
  return nil
end

def select_date
  tr = tr_find
  return false unless tr
  select = tr.find_element(css: "select")
  select = Selenium::WebDriver::Support::Select.new(select)
  select.select_by(:text, "打刻申請")
  wait.until { @driver.find_element(id: "recording_timestamp_table").displayed? }
  return true
end

def work_record
  table = @driver.find_element(id: "recording_timestamp_table")

  select =  Selenium::WebDriver::Support::Select.new(table.find_element(id: "recording_type_code_1"))
  select.select_by(:text, "出勤")
  text = table.find_element(id: "recording_timestamp_time_1")
  text.send_keys(@in_time)

  if @in_message && @in_message.length > 0
    message = table.find_element(name: "request_remark_1")
    message.send_keys(@in_message)
  end

  select =  Selenium::WebDriver::Support::Select.new(table.find_element(id: "recording_type_code_2"))
  select.select_by(:text, "退勤")
  text = table.find_element(id: "recording_timestamp_time_2")
  text.send_keys(@leave_time)

  if @leave_message && @leave_message.length > 0
    message = table.find_element(name: "request_remark_2")
    message.send_keys(@leave_message)
  end

  @driver.find_element(id: "button_01").click
  wait.until { @driver.find_element(class: "htBlock-autoNewLineTable").displayed? }
end

def wait
  @wait ||= Selenium::WebDriver::Wait.new(:timeout => 3) # second
end

# 引数をparse
option_parse

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--no-sandbox')
options.add_argument('--headless')
options.add_argument('--disable-gpu')
options.add_argument('--window-size=1280,1800')

# headless オプションでヘッドレスブラウザモード
@driver = Selenium::WebDriver.for :chrome, options: options

# loginして登録
login
select_date
work_record

# logging
puts "#{@date_at.strftime("%Y-%m-%d")} in: #{@in_time} leave: #{@leave_time}"

@driver.quit