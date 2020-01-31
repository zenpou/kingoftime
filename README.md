# kingoftime

king of time 打刻コマンド  
会社でking of time を打刻するのが面倒だったので作ったスクリプト

## 準備
* dockerをインストールする
* .env.sample をcopyして、同階層に.envを作成する
* .env を開いて編集(.envの設定値一覧を参照)
* 下記コマンドを実行

```bash
docker-compose build
docker-compose run --rm kot --help
```

## 実行の例

```bash
# 現在時間で登録する
docker-compose run --rm kot

# 退勤時間を指定して登録する
docker-compose run --rm kot --l 21:00

# 遅刻理由を入力する
docker-compose run --rm kot --i 11:00 --in-biko 通院のため

# 日付を指定して登録する
docker-compose run --rm kot -d 2020-01-27 -i 09:00 -l 18:00
```

## .envの設定値一覧
| name | value | memo |
----|---- |---- 
| KOT_USER_ID | your user id | |
| KOT_PSSWORD | your password | |
| IN_TIME | 10:00 | 時間（出勤） |
| OUT_TIME | 19:00 | 時間（退勤） |
| OVERTIME_ROUND | 10 | 残業時間の丸め(この例だと10分未満切捨て) |
| REQUIRED_OVERTIME_REASON_MIN | 30 | 残業理由（退勤備考欄）の記入を必須とする残業時間 |
| DEFAULT_OVERTIME_REASON | とても忙しいため | 自動で設定される残業理由（設定しない場合は対話的に入力を求められる） |

## test

```bash
docker-compose run --rm kot-test
```