# IAM認証情報を作成する
- AWSコンソールから発行する
  - IAM→ユーザ→認証情報→アクセスキー→アクセスキーの作成→.csvファイルのダウンロード

-----------------------------------

# terraform.tfvarsの作成
- terraform.tfvarsを作成し、アクセスキーの情報を記述する

```js:terraform.tfvars
aws_access_key = ""
aws_secret_key = ""
```

- terraform.tfvarsをapply時に読み込まれるようにする

```js:providers.tf
variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}
```

- terraform.tfvarsをバージョン管理の対象外とする
  - git管理の場合は、.gitignoreにファイルを追加

-----------------------------------

# AWS CLIの環境構築
- MSIインストーラをダウンロードして実行
  - https://awscli.amazonaws.com/AWSCLIV2.msi
- プロンプトを閉じてからawsコマンドの実行確認
- 
-----------------------------------

# AWS CLIの環境設定
- クレデンシャル情報を登録
  - ```~/.aws/credentials```を作成する

```sh:
[dev] #プロファイル名
aws_access_key_id=<アクセスキー>
aws_secret_access_key=<シークレットアクセスキー>
```

- 基本設定を登録
  - ```~/.aws/config```を作成する

```sh:
[profile dev] #プロファイル名
region=<リージョン名>
output=json
```


- 設定ファイルの読み込み
  - ```aws configure --profile <プロファイル名>```を実行

-----------------------------------


# keybaseの環境構築
- ダウンロード：https://keybase.io/download
- ユーザを作成(keybase:に指定するユーザ名となる)
- PGPキーを生成 (公開鍵が作成され、keybaseに登録しているデバイスから復号化が可能に)
- [参考](https://qiita.com/ldr/items/427f6cf7ed14f4187cd2)


-----------------------------------

# aws-vaultの環境構築

- 参考: https://github.com/99designs/aws-vault

## Chocolately・aws-vaultのインストール
- [ダウンロードページ](https://chocolatey.org/install)からスクリプトをコピー
- 管理者権限でPowershellを開き、スクリプトを実行

```sh:
# Chocolatelyのインストール
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# aws-vaultのインストール
choco install aws-vault
```

- 環境変数Pathに```C:\ProgramData\chocolatey\bin```を追加する


## 認証情報をaws-vaultにセット

**IAM Identity Centerを有効化している場合**
- シングルサインオンのページにて、```Command line or programmatic access```をクリック
- 必要な認証情報が払い出され、必要なプロセスも表示してくれる
- 環境変数を利用する場合
  - 認証情報を環境変数にセットするコマンド群をコピペする (```SET AWS_ACCESS_KEY...```)
  - MFAデバイスをIDP側で管理しているのであればAWS側にMFAデバイスはないが、スイッチロールの対応は必要
  - aws-vaultを使用せずにterraform applyを実行する (aws-vaultはinvalid ClientTokenとなる)
- providers.tfにprofileを追記する

```js:
provider "aws" {
  profile = "ccc"
}
```

**aws-vaultにユーザ認証情報を追加する**
```sh:
# ユーザ認証情報を追加 (profile_name → ~/.aws/configに定義されるプロファイル名)
aws-vault add <profile_name>
    # アクセスキー・シークレットアクセスキーを求められる

# 確認
aws-vault list 
```

**```~/.aws/config```を編集**
- <profile_name>で指定したプロファイルが追加されている
  - region:リージョン名を追加
- 必要に応じて、MFA・スイッチロール用のプロファイルを作成する
  - source_profile: プロファイル名
  - role_arn:スイッチ先ロールのARN
  - mfa_serial：MFAデバイスのARN

```sh:
[profile aaa_bbb]
region=ap-northeast-1

[profile ccc]
source_profile = aaa_bbb
role_arn=arn:aws:iam::<account-id>:role/<role-name>
mfa_serial=arn:aws:iam::111111111111:mfa/aaa_bbb
region=ap-northeast-1
```

**実行**

```sh:
aws-vault exec ccc <command>
```