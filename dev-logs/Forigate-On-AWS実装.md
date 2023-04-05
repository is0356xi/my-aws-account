# Fortigate on AWSで色々試す

- Todo
  - NLBの可用性調査：アクティブ・アクティブで片方を落としてみる
    - 落とすのはクライアントが繋いでいないほう
    - Fortigateの管理画面から確認？
    - クライアントはpingし続ける？
  - GWLBで置き換えられるか？
  - クライアント→VPNサーバ→インターネットの構築方法

-----------------------------------
# Fortigate on AWSでVPN構築

## ①VPNサーバ構築

### 周辺コンポーネント
- VPC
- Subnet
- IGW
- RouteTable
- SecurityGroup
- ENI-ElasticIP

### FortigateVMの起動
- MarketPlace or EC2コンソールでFortigateのライセンスを購入して起動


### ポート(ENI)の追加設定

**FortigateVMに合計3ポート持たせる**
- port1: マネジメントポート (起動時のパブリックIP割り当てを有効化)
- port2: クライアント接続用のポート (ElasticIPをアタッチ)
- port3: 内部用のポート (ENI=プライベートIPをアタッチ)
  
**上記ポートに該当するENIとElasticIPを作成**
- ENIを作成
  - セキュリティグループをアタッチ
  - インスタンスにアタッチ
- EIPを作成
  - パブリックIPはAmazonのパブリックIPプール
  - ENIにアタッチ

**ENI・EC2のデフォルトルーティング設定を変更**
- ENIの```送信元/送信先の変更チェック```オプションを無効化する
  - ENIのデフォルト設定：自身のIPが送信元または送信先になっているパケット以外を受け取らない
- EC2のコンソールからも無効化可能
  - アタッチされている全てのENI & EC2のソース/宛先チェック設定を無効化してくれる
- コンソールで変更した後にterraform applyをする場合
  - 差分として検知されてchangeが発生する
  - コンフリクト？してエラーになるので、設定をデフォルトに戻してからapplyする
  - ※```source_dest_check = false```の設定を追記したので、この設定変更手順はいらないかも
  - 念のためEC2のコンソールで確認



**起動後、初期設定を行う**
- port1にhttpsでアクセス

```sh:
https://<port1のIPアドレス>
```

- ログイン情報
  - ```ユーザ名```：admin,  ```パスワード```：インスタンスID
- ホスト名を設定できる。
  - ```Test-FortigateVM-Vpn-Proxy```


**Fortigateの管理画面でポート追加処理**
- port2 (クライアント接続用)の追加
  - Network → Interafaces
  - port2がダッシュボード上に表示されるので、Editをクリック
  - port2にIPアドレスを割り当てる
    - ロール：WANを選択　(インターネットに向いているポートのため)
    - アドレスモード：DHCPを選択 (AWSで割り当てたIPが自動で付与される)
    - Retrieve default gateway from serve：ONにする
    - Administrative Access： Pingを選択 (疎通確認する)
- port3 (内部用)の追加
  - Network → Interafaces
  - port3がダッシュボード上に表示されるので、Editをクリック
  - port3にIPアドレスを割り当てる
    - ロール：LANを選択　(VPNセッション確立後のプライベート接続用ポートのため)
    - アドレスモード：DHCPを選択 (AWSで割り当てたIPが自動で付与される)
    - Retrieve default gateway from serve：ONにする

```sh:
# 疎通確認を行う
ping <port2のpublicIP>
```

**CLIでやる場合**

```sh:
# port2 (クライアント接続用ポート)の設定
config system interface
edit port2
set alias public
set mode dhcp
set allowaccess ping
next
end

# port3 (内部=AWS用ポート)の設定
config system interface
edit port3
set alias private
set mode dhcp
next
end
```

### ルーティング設定

**VPCのアドレスをFortigateに登録**
- Policy & Objects → Addresses → Create New → Addressで新規作成
  - オブジェクトの名前：任意
  - Type：サブネット
  - IP/Netmask：VPCのCIDR


**VPCからWAN側へのトラフィックを許可するためのFWポリシーの作成**
- VPCからWANヘ向かうトラフィックを許可するポリシー作成
- Policy & Objects → Firewall Policy → Create Newで新規作成
  - ポリシー名：VPC to WAN
  - 着信インターフェース：port3 (VPC側)
  - 発信インターフェース：port2 (WAN側)
  - 送信元：VPC (上記手順で作成したオブジェクト)
  - 宛先：allにする → 自分のGIPに該当するアドレスオブジェクトを作成してもいいかも
  - サービス：ALL (プロトコルを限定できる)
  - 検査モード：フローベース or プロキシベースを選択可能　→　※要調査
  - NAT：有効化


### SSL-VPN環境の構築

**VPNユーザの作成**
- User & Authentication → User Definetion → Create New
  - ユーザタイプ：ローカルユーザ (外部連携可能、LDAPなど)
  - ユーザ名・パスワード：任意の値 (vpn-test-user)
  - コンタクト情報：MFAを有効化するかどうか
  - エキストラ情報：ユーザの有効化・グループの設定？

**SSL-VPNの設定**
- VPN → SSL-VPN Settings
  - 着信インターフェース：port2 (WAN側)
  - リッスンポート：4433 (管理用と競合するので443から変更)
  - サーバ証明書：Fortinet_Factoryを選択 (デフォルトだけど大丈夫か確認される)
  - ※DNS Server：うまいこと設定すればGWLBに活かせるかも？
- Authentication/Portal Mapping → Create New
  - ユーザ：作成したユーザを追加
  - ポータル：tunnel-accessを選択　→ ※要調査
- All Other Users/Groupsを選択し、Edit
  - web-accessを付与

**VPNトラフィックを許可するためのFWポリシーの作成**
- SSL-VPNトンネルから来たVPC宛のトラフィックを許可するポリシー作成
- Policy & Objects → Firewall Policy → Create Newで新規作成
  - ポリシー名：VPN to VPC
  - 着信インターフェース：SSL-VPNトンネルインターフェース
  - 発信インタフェース：port3 (VPC側)
  - 送信元：SSL_VPN_TUNNEL_ADDR1 と 作成したVPNユーザ を追加
  - 宛先：VPC (上記手順で作成したオブジェクト)
  - サービス：ALL (プロトコルを限定できる)
  - 検査モード：フローベース or プロキシベースを選択可能　→　※要調査
  - NAT：無効化


### 接続テスト
- FortiClient VPNをダウンロード
  - https://www.fortinet.com/support/product-downloads#vpn
- VPN設定
  - リモートGW：port2のEIP (クライアント接続用ポートのGIP)
  - ポートの編集：VPN設定時に443から変更したポート (4433)

- VPCに配置されたプライベートなEC2との疎通確認

```sh:
ping <テスト用EC2のプライベートIP>
```


------------------------------------------------

# NLBでFortigate VMを冗長構成にする

## 冗長構成に必要なリソースを作成
- Fortigateから見たデフォルトゲート用のサブネットを作成
  - 各Fortigateで同一のデフォルトゲートウェイを参照するように設定


## Auto-Scall設定 (※未達)

- 各FortigateのCLIから以下設定を実行する
  - system auto-scale：プライマリー・セカンダリーで分ける
  - router static：デフォルトゲートは各VMで同一のIPにする
    - 本環境では、Fortigateクライアント接続用のサブネット内のアドレスを指定

```sh:
config system interface
edit port2
set alias public
set mode static
#set ip <port2に該当するENIのプライベートIP> 255.255.255.0
set ip 10.0.1.11 255.255.255.0
set allowaccess ping https ssh fgfm
set mtu-override enable
set mtu 9001
next
edit port3
set alias private
set mode static
# set ip <port3に該当するENIのプライベートIP> 255.255.255.0
set ip 10.0.10.200 255.255.255.0
set allowaccess ping https ssh fgfm
set mtu-override enable
set mtu 9001
next
end
config router static
edit 1
set device port2
# set gateway <デフォルトゲートとするIPアドレス>
set gateway 10.0.1.1
next
end
config system auto-scale
set status enable
# set role <primary または secondary>
set role primary
set sync-interface port2
# set psksecret <事前共有キー>
set psksecret LBTest123#
end
```

## Fortigate VMを二台分設定する

**注意点 (いらないかも)**
- 各Fortigateの設定でVPN-IPプールが競合しないようにしておく
  - Forti①：10.212.133.200 ~ 10.212.133.210
  - Forti②：10.212.134.200 ~ 10.212.134.210
- 上記アドレスに合わせて、VPNトラフィックをさばくルートテーブルを設定する

```t:
# ルート定義
routes = {
  toward_fortigate_1 = {
    destination = "10.212.133.0/24"
    type_dst    = "network_interface"
    next_hop    = "eni_for_FortigateVM_Port3"
  }
  toward_fortigate_2 = {
    destination = "10.212.134.0/24"
    type_dst    = "network_interface"
    next_hop    = "eni2_for_FortigateVM_Port3"
  }
}
```

## NLBの作成手順

**create loab balancer → NLB Create**

- 基本設定
  - 名前：任意
  - スキーム：インターネットフェイシング (外部or内部を選択)
  - IPアドレスタイプ：IPV4
- ネットワークマッピング
  - VPC：Fortigateの外部公開用portが存在するVPCを選択
  - Subnet：外部公開用portを配置しているサブネット
  - IPv4設定：AWS割り当て (ElasticIPも一応選択できる)
- Listners and routing
  - Protocol：TCP
  - Port：4433 (Fortigate設定時にVPNのリッスンポートに指定した値)
  - Default Action：リンクからターゲットグループ作成する

**Specify group details**
- 基本設定
  - ターゲットタイプ：IP Addresses
  - 名前：任意
  - Protocol：TCP
  - Port：4433 (Fortigate設定時にVPNのリッスンポートに指定した値)
  - VPC：Fortigateの外部公開用portが存在するVPCを選択
  - プロトコルバージョン：HTTP1
- ヘルスチェック
  - Protocol：TCP
  - チェックパス：/
  - Advanced health check settingsを選択
    - Port → Override：4433
- Next

**Register Targets**
- IPアドレス
  - ネットワーク：Fortigateの外部公開用portが存在するVPCを選択
  - IPアドレスの追加：EIPのプライベートIP (FortigateのVPNリッスンポートに該当するもの)
  - Include as pending belowをクリック
  - create target groupをクリック
  - (NLBの画面に戻り作成したターゲットグループを選択)


## 接続テスト
- NLBのDNS名をコピー
- Forigate VPN Clientの設定
  - リモートGWにDNS名を貼り付け
  - ポートを4433に編集

```sh:
# 接続確認
ping <テスト用EC2のプライベートIP>
```

## NLBのターゲットにFortigate×2を指定
- VPN接続が確立された直後に切断される → ※要調査
  - Fortigate側でHA設定を入れる必要がありそう？(https://nwengblog.com/fortigateha/)
  - クラスタ構成の場合、TCPセッション引継ぎができるらしい
    - https://csps.hitachi-solutions.co.jp/fortinet/faq/FG-41-0025/index.html

## ToDo
- Fortiが公開している情報をもとにHA構成の調査
  - Githubにterraformが公開
    - https://github.com/fortinet/fortigate-terraform-deploy/tree/main/aws/7.2/ha-single-az
  - on AWSでのHAについてもドキュメント有
    - https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/aws-administration-guide/176205/ha-for-fortigate-vm-on-aws
  

------------------------------------------------

# FortigateとGWLBでトラフィック検査

- 行きのトラフィック
  - クライアントPC → IGW → GWLBエンドポイント → GWLB → FortigateVM → IGW　→ インターネット
- 帰りのトラフィック
  - インターネット → IGW → FortigateVM →　GWLB → GWLBエンドポイント → IGW　→ クライアントPC

- 参考になりそう
  - https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/aws-administration-guide/570271/north-south-security-inspection-to-customer-vpc
  - https://qiita.com/ya-sasaki/items/19bb91e60c552894f50f
  - https://docs.fortinet.com/document/fortigate-public-cloud/7.2.0/aws-administration-guide/386625/creating-the-lb-endpoint


## GWLBを作成する前の準備

**terraformで必要なリソースを作成する**
- GWLBの作成はコンソールから行う
- 他リソースをterraformにて作成
  - VPC
  - Subnet
  - セキュリティグループ
  - ルートテーブル
  - インターネットゲートウェイ
  - VPCエンドポイント (Systems Manager用)

**テスト用インスタンスにIAMインスタンスプロファイルをアタッチ** 
- Session Mangagerからテスト用インスタンスにSSHする
- SystemsManagerの権限が必要なため、IAMロールを作成しアタッチする
  - 信頼ポリシー：EC2のAssumeRoleを許可
  - 許可ポリシー：AmazonSSMManagedInstanceCore
- IAMインスタンスプロファイルをアタッチ → EC2を再起動
  - 再起動しないとインスタンスメタデータを使ったAssumeRoleが走らない

## GWLB・エンドポイントの作成

**GWLBを作成**
- ネットワークマッピング：GWLB自体を配置するVPC・サブネットを選択
  - GWLBエンドポイントとは別。
- GWLB作成画面からターゲットグループを作成すると楽
- IP listener routing：作成したターゲットグループを選択
- GWLB作成後、クロスゾーン負荷分散を有効化しておく
  - Edit load balancer attribues → Target selection configuration → ON 

**ターゲットグループを作成**
- ターゲットタイプ：IPアドレスを選択
- protocol：GENEVEで固定されている
- VPC：FortigateのリッスンポートがあるVPCを選択
- HealthCheck
  - プロトコル：HTTPS
  - パス：/
  - Port：443
- IP addresses：FortigateのリッスンポートのIPを追加 (プライベートIP)
  
**エンドポイントサービスを作成**
- ロードバランサーのタイプ：ゲートウェイ
- 承諾が必要：チェックを外す (テスト用なので)
- サービス名が払い出されるのでコピー

**エンドポイント接続 → エンドポイント接続を作成**
  - その他のエンドポイントサービスを選択
  - サービス名：払い出されたサービス名を貼り付け
  - サービスの検証をクリック
  - VPC：GWLBエンドポイントを配置するVPCを選択
  - サブネット：GWLBエンドポイントを配置するサブネットを選択


## Fortigate VMの設定

**アタッチしたENIを反映させる**

```sh:
# マルチVDOMモードの有効化
config system global
set vdom-mode multi-vdom

# VDOM追加 (エラーになる)
config vdom
edit "FG-traffic" 
# Could not create VD, all VD licenses have been used.
↓
# rootに設定追加する
config vdom
edit "root"

# GENEVEインタフェースの追加
config system geneve
edit "awsgeneve"
set interface "port3"
set type ppp
set remote-ip <GWLBのターゲットに指定したENIのプライベートIP>
show
next
end
next
end
```

**ファイアウォールポリシーを設定**


## ルーティング設定
- AWS側でルーティング設定を行い、Fortigate側のパケットキャプチャで確認する形
  - Fortigateにまずは届くことを確認してからFortigate側のポリシーなどをいじる

### AWS側

**ルートテーブルの編集**
- テスト用インスタンスを起動しているサブネットのルートテーブル
  - 送信先：0.0.0.0/0
  - ターゲット：GWLBのエンドポイント

### Fortigate側



-------------------------------------------------
# VPCフローログの解析 (S3に保存する場合)
- S3, CloudWatch, Kinesisにフローログを送信可能
- 送信先によってIAM設定が異なるので注意。
  - https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/flow-logs.html
- 
## IAMロールの作成
- VPCフローログがS3にデータを送信するための許可を設定
  - 信頼ポリシー：vpc-flow-logs.amazonaws.comのAssumeRoleを許可
  - インラインポリシー：logs:*のアクションを許可

**信頼ポリシー**

```json:
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": {
              "Service": "vpc-flow-logs.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
      }
  ]
}
```

**インラインポリシー**

```json:
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogDelivery",
            "logs:DeleteLogDelivery"
          ],
          "Resource": "*"
      }
  ]
}
```

## VPCフローログの設定

**S3バケットを作成**
- VPCフローログの保存先となる

**VPCフローログの作成**
- VPCコンソールからフローログを選択し、作成をクリック
  - 名前：任意
  - フィルタ：すべて
  - 最大集約間隔：10分
  - 送信先：S3バケットに送信を選択し、該当するS3ARNを入力
  - ログレコード形式：AWSのデフォルト
  - ログファイル形式：Parquet (データ量が多いほど圧縮率が高くなる形式)
  - Hive互換S3プレフィックス：有効化 (データを他サービスで取り込む際、より細かく範囲を指定可能に)
  - 時間別にログをパーティション分割：24時間 (デフォルト)


## AthenaのコンソールでS3バケットデータを取り込む**

- データベースを作成
  - SQLを実行してデータベースを作成し、作成したデータベースを選択

```sql:
CREATE DATABASE VPCFlowLogs;
```


- 外部データ(S3バケット)を取り込む
  - CREATE EXTERNAL TABLEを使用
    - VPCフローログの各列を定義
  - PARTITIONED BY：ここにセットされた変数を用いてロードするデータを限定できる
    - S3のHive形式のKeyに合わせる必要あり → ※下記参照
  - TERMINATED：VPCフローログはデフォルトでスペース区切りになっているのでスペースを指定

```sql:
CREATE EXTERNAL TABLE IF NOT EXISTS fortigate_flow_log (
  `version` int, 
  `account_id` string, 
  `interface_id` string, 
  `srcaddr` string, 
  `dstaddr` string, 
  `srcport` int, 
  `dstport` int, 
  `protocol` bigint, 
  `packets` bigint, 
  `bytes` bigint, 
  `start` bigint, 
  `end` bigint, 
  `action` string, 
  `log_status` string
)
PARTITIONED BY (year string, month string, day string)
STORED AS parquet
LOCATION 's3://<bucket-name>/AWSLogs/aws-account-id=<account-id>/aws-service=vpcflowlogs/aws-region=ap-northeast-1/'
TBLPROPERTIES ("skip.header.line.count"="1");
```

### Hive互換S3プレフィックスの有効化との関係性

**パーティションを自動で追加してくれるかしてくれないかが変わる**
- 有効化しておくと、```MSCK REPAIR TABLE <table>```を実行するだけでいい
  - **パーティションが自動で追加される**
  - **Hive形式をAthenaクエリの条件式に使用可能になる**
  - https://docs.aws.amazon.com/ja_jp/athena/latest/ug/partitions.html

```sql:
MSCK REPAIR TABLE fortigate_flow_log
```

- 有効化してない場合、手動でパーティションを追加する必要がある
  - 2015-01-01のデータを使いたい場合、ユーザ側で該当のS3オブジェクトを指定する必要がある
  - ALTER TABLEコマンドを使用して追加する例。

```sql:
ALTER TABLE elb_logs_raw_native_part ADD PARTITION (dt='2015-01-01') location 's3://athena-examples-us-west-1/elb/plaintext/2015/01/01/'
```

**PARTITIONED BYで指定するのは```Hive形式のkey```**
- 年単位(year)以下を分割したいケース
  - ```where year='2023' and month = "04"```
  - 上記のようにロードデータを限定したい場合、```year```と```month```をPARTITIONED BYで指定
- Hive形式のkeyはS3のオブジェクト名で確認する
  - 一例：aws s3 lsで実行して```PRE```を確認してみる

```sh:
aws s3 ls s3://<bucket-name>/AWSLogs/aws-account-id=<account-id>/aws-service=vpcflowlogs/aws-region=ap-northeast-1/

# PRE year=xxxx/ と表示される → PREのkeyをPARTITIONED BYに指定できる
```


## パーティションをロードする

- Hive互換S3プレフィックスの有効化が有効化されている前提

```sql:
MSCK REPAIR TABLE fortigate_flow_log;

-- Partitions not in metastore:	fortigate_flow_log:year=2023/month=04/day=01
-- Repair: Added partition to metastore fortigate_flow_log:year=2023/month=04/day=01
```