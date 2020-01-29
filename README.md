# kingoftime

king of time 打刻コマンド  
会社でking of time を打刻するのが面倒だったので作ったスクリプト

## 準備
* dockerをインストールする
* .env.sample をcopyして、同階層に.envを作成する
* .env を開く
    * KOT_USER_ID, KOT_PSSWORDを設定する
    * 勤務開始, 終了時間を設定する
* 下記コマンドを実行

```bash
docker-compose build
docker-compose run --rm kot --help
```

## 実行

```bash
# 現在時間で記録
docker-compose run --rm kot

# 退勤時間を指定
docker-compose run --rm kot --l 21:00

# 遅刻理由を入力する
docker-compose run --rm kot --i 11:00 --in-biko 通院のため
```