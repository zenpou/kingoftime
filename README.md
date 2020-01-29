# kingoftime

king of time 打刻コマンド

会社でking of time を打刻するのが面倒だったので作ったスクリプト

# インストール方法

1. ChromeDriver install

http://chromedriver.chromium.org/downloads

2. selenium-webdriver インストール

`gem install selenium-webdriver`

3. 自分のログインIDとパスワードを書いたlogin.ymlを用意

4. IN_TIMEとOUT_TIMEの時間を変更

5. 自分のpath通ってる所にコピーすると更に便利

ex.  `cp ~/Download/kingoftime.rb /usr/local/bin/kingoftime`

# yaml sample login.yml

```
id: "cgu..........."
pass: "password"
```
