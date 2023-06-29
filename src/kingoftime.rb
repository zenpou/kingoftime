#!/usr/bin/env ruby

USER_ID = ENV['KOT_USER_ID']
PSSWORD = ENV['KOT_PSSWORD']
IN_TIME = ENV['IN_TIME']
OUT_TIME = ENV['OUT_TIME']
OVERTIME_ROUND = ENV['OVERTIME_ROUND'].to_i
REQUIRED_OVERTIME_REASON_MIN = ENV['REQUIRED_OVERTIME_REASON_MIN'].to_i
DEFAULT_OVERTIME_REASON = ENV['DEFAULT_OVERTIME_REASON']

require 'net/http'
require 'uri'
require 'optparse'
require 'date'
require 'selenium-webdriver'

URL = "https://s3.kingtime.jp/admin"

def option_parse
  @date_at = Date.today.strftime("%Y-%m-%d")
  @in_time = IN_TIME
  @leave_time = leave_time_make(Time.now)
  @in_message = ""
  @leave_message = ""

  opt = OptionParser.new
  opt.on("-d #{@date_at}", "--date", "日付を指定する"){|v| @date_at = v}
  opt.on("-i #{@in_time}", "--intime", "時間（出勤）を指定する"){|v| @in_time = v}
  opt.on("-l #{@leave_time}", "--leavetime", "時間（退勤）を指定する"){|v| @leave_time = v}
  opt.on("-m #{@in_message}", "--in-biko", "備考（出勤）を指定する"){|v| @in_message = v}
  opt.on("-b #{@leave_message}", "--out-biko", "備考（退勤）を指定する"){|v| @leave_message = v}
  opt.on("-a #{@auxiliary}", "--auxiliary", "補助項目申請をする"){|v| @auxiliary = v}
  opt.on("-n", "--not-apply", "打刻申請をしない"){|v| @not_apply = v}
  opt.banner = "note: king of timeの勤怠情報を登録します\n\nOptions:\n"
  opt.parse!(ARGV)

  @date_at = Date.parse(@date_at)
  if @leave_message.length == 0 && is_overtime_reason_required(@leave_time)
    @leave_message = get_overtime_reason
  end
end

def make_driver
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,1800')
  
  # headless オプションでヘッドレスブラウザモード
  @driver = Selenium::WebDriver.for :chrome, options: options
end

def time_to_min(time)
  hour, min = time.split(":")
  hour.to_i * 60 + min.to_i 
end

# 残業理由入力必須判定
def is_overtime_reason_required(leave_time)
  overtime = time_to_min(leave_time) - time_to_min(OUT_TIME)
  return overtime > REQUIRED_OVERTIME_REASON_MIN
end

# 残業理由を返す
def get_overtime_reason
  if DEFAULT_OVERTIME_REASON.empty?
    return stdin_get("残業理由を入力してください")
  else
    return DEFAULT_OVERTIME_REASON
  end
end

def stdin_get(message)
  print "残業理由を入力してください"
  return STDIN.gets.chomp
end

def leave_time_make(now)
  min = (now.min / OVERTIME_ROUND).to_i * OVERTIME_ROUND
  "#{"%02d" % now.hour}:#{"%02d" % min}"
end

## browser操作
def login
  @driver.manage.timeouts.implicit_wait = 30
  @driver.navigate.to URL

  path = __FILE__
  if File.exist?(path) && File.ftype(path) == 'link'
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

def month_find(count = 0)
  return if count > 5
  h2_block = @driver.find_element(css: '.htBlock-mainContents h2 span')
  date_at_month = Date.new(@date_at.year, @date_at.month, 1)
  h2_block.text =~ /^(\d{4}\/\d{2}\/\d{2})/
  now_month = Date.parse($1)
  return if now_month == date_at_month
  button = nil
  if now_month < date_at_month
    button = @driver.find_element(id: 'button_next_month')
  end
  if now_month > date_at_month
    button = @driver.find_element(id: 'button_before_month')
  end
  button&.click
  wait.until { @driver.find_element(class: "htBlock-autoNewLineTable").displayed? }
  month_find(count + 1)
  return
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

def auxiliary
  if @auxiliary.nil? || @auxiliary.length == 0
    return
  end
  tr = tr_find
  return false unless tr
  select = tr.find_element(css: "select")
  select = Selenium::WebDriver::Support::Select.new(select)
  select.select_by(:text, "補助項目申請")
  wait.until { @driver.find_element(id: "supplemental_working_record_table").displayed? }
  table = @driver.find_element(id: "supplemental_working_record_table")
  select =  Selenium::WebDriver::Support::Select.new(table.find_element(id: "supplemental_working_record_setting_1"))
  select.select_by(:text, @auxiliary)
  wait.until { @driver.find_element(id: "drop_down_option_1").displayed? }
  @driver.find_element(id: "button_01").click
  wait.until { @driver.find_element(class: "htBlock-autoNewLineTable").displayed? }
end

def wait
  @wait ||= Selenium::WebDriver::Wait.new(:timeout => 3) # second
end

## main処理
option_parse
make_driver

login

month_find
unless @not_apply
  select_date
  work_record
end
# 補助項目申請
auxiliary


puts "#{@date_at.strftime("%Y-%m-%d")} in: #{@in_time} leave: #{@leave_time}, in_biko: #{@in_message} leave_biko: #{@leave_message}"

@driver.quit
