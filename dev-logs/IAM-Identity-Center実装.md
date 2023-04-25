# AWSの勉強用リポジトリ

---------------------------
# 初期セットアップ

## ①rootユーザのMFA
- rootユーザでログイン
  - rootユーザのMFAを有効化

## ②Organizations・IAM Identity Centerを有効化する
- Organizaions
  - マルチアカウントを一元管理 (サービス許可・コスト・タグなど)
- IAM Identity Center
  - マルチアカウントの認証情報を一元管理
  - 複数アカウントに一つの認証情報でログイン可能に

-----------------------------
# IAM Identity Centerのセットアップ
- 参考: https://dev.classmethod.jp/articles/federate-azure-ad-and-aws-iam-identity-center/
- Identity Centerの作成後、アイデンティティソースを変更可能
  - 「Identity Center」、「AWS Managed Microsoft AD」、「外部のIDP」
- 本環境では、Azure ADを用いるため、```「外部のIDP」```を選択


## ①Azure ADの作成
- Terraformにてグループ・ユーザを作成

```sh:
cd envs/azure/dev
terraform init
az login
../../../scripts/apply.ps1
```

## ②SAMLの信頼関係構築

- ```Identity Center側```
  - SAMLメタデータを作成し、ダウンロード
- ```Azure AD側```
  - エンタープライズアプリケーション(AWS Identity Center)を追加
  - SAMLメタデータをアップロードし、信頼関係設定を保存
  - フェデレーションメタデータが生成されるのでダウンロード
- ```Identity Center側```
  - 外部Identity Providerの設定画面からフェデレーションメタデータを追加

## ③ユーザ/グループ情報の同期設定
 
**SCIMによる自動同期設定**
- ```Identity Center側```
  - 自動プロビジョニングを有効化
  - 「SCIMエンドポイントとアクセストークン」が払い出される
- ```Azure AD側```
  - ```プロビジョニング```を選択し、「SCIMエンドポイントとアクセストークン」を入力
  - マッピング設定を行う
    - Identity Centerで必須項目となっている姓・名がAzureAD側で指定されていないケースへの対処
    - ```surname``` / ```givenName```の「nullの場合の既定値」に"default"を設定
  - ```ユーザとグループ```を選択し、同期したいユーザ・グループを追加する
    - **※無料のAzureADだとグループを追加できない？**
  - ```プロビジョニング```を選択し、プロビジョニング開始を実行する


## ④シングルサインオンのテスト
- Azureにログインしていないユーザ情報でテストをする際は拡張機能のインストールが必須
- Azure ADのコンソールからインストール画面に飛べる


## ⑤IAM Identity Centerで許可セットを作成・アタッチする
- 同期されたユーザ・グループに対して、AWSのIAMポリシーをアタッチすることでアクセス制御ができる。

**(1)許可セットの作成**
- ```マネージド許可セット```または```カスタム許可セット```を選択 (本環境ではカスタム許可セット)
  - マネージドポリシー・カスタマーポリシーなどを選択可能
  - 管理者を想定しているため、```AdministratorAccess```を選択
- 許可セットの詳細設定を行う
  - セッションの有効時間
  - リレー状態 (IDPの認証後、どのURLにリダイレクトするか)
    - AWSマネジメントコンソールのURLを指定
    - https://ap-northeast-1.console.aws.amazon.com/console/home 

**(2)作成した許可セットとAWSアカウントの関連づけ**
- AWSアカウントをクリックし、許可セットを関連づけたい```AWSアカウント```を選択
- 許可セットをアタッチする```ユーザ・グループ```を選択
- アタッチしたい```許可セット```を選択


------------------------------------------

# 開発者用ユーザを作成・セットアップする

## ①Azure ADにユーザを追加
- 開発者用のグループを作成し、ユーザを作成する

## ②AWS IAM Identity Centerと同期するユーザに追加
- Azure AD → エンタープライズアプリケーション → ユーザとグループから作成したユーザを追加 

## ③Identity Centerで許可セットを作成する
- AssumeRoleの許可を定義したポリシーを作成し、ユーザにアタッチする
- AssumeRoleするIAMロールはPowerUserAccessとする

**カスタム許可セット**
- ```インラインポリシー```
  - AssumeRoleを許可するためのポリシーを記述
  - 以下の例では、```Resource=*```としているため、全てのIAMロールを参照できる
    - 最小権限が推奨される　→　適切なIAMロールARNを記述する

```json:
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "PermissionforSwitchRole",
        "Effect": "Allow",
        "Action":[
            "sts:AssumeRole",
            "iam:GetRole",
            "iam:ListAttachedRolePolicies"
        ],
        "Resource":["*"]
    }
}
```

- ```許可セットの詳細```
  - セッション時間・リレー状態を設定
  - リレー状態：```https://ap-northeast-1.console.aws.amazon.com/console/home```

## ④許可セットを開発者用ユーザにアタッチする
- マルチアカウント許可のAWSアカウントから、以下を設定する。
  - ①対象となる```AWSアカウント```を選択
  - ②許可セットをアタッチする``ユーザ``を選択
  - ③ユーザにアタッチする```許可セット```を選択

## ⑤スイッチロール用のIAMロールを作成し、許可セットを編集
- IAMロール → ロールの作成で作成画面へ遷移
- ```カスタム信頼ポリシー```を選択
  - SSO用のロールがAssumeRoleできるように許可設定を行う
  - **※SSO用のロールのARNが特殊な形式な点に注意**

```json:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<account-id>:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_<Permission-Sets-Name>"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

- 許可ポリシーを設定
  - ```PowerUserAccess```を選択


--------------------------------------------------------

# MFAを有効化する手順

- 現在は外部IDpではMFAサポートされていないらしい
  - https://docs.aws.amazon.com/singlesignon/latest/userguide/mfa-considerations.html
- Azure ADをIDpとすると、外部IDpになってしまう
  - Azure ADとAD ConnectorでAWS Managed Microsoft ADにユーザを連携
  - AWS Managed Microsoft ADをIDpに指定したらいけるかも？


## **CLIの注意点**
- 参考: https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-configure-role.html
  - 認証情報を使用してCLIコマンドを実行すると有効期限が切れるまでCacheに認証情報が保存される
  - IAMポリシーやCLIのConfigファイルを編集しても、キャッシュが原因で期待通りの動作にならない
  - ポリシーなどを編集して動作を検証する場合は、キャッシュを消しておくと安全
 
```sh:
Remove-Item -Recurse -Force $env:USERPROFILE\.aws\cli\cache
```

## IAM Identicy CenterでMFAデバイスを追加する
- SSO用のURLにアクセスし、MFAを有効化したいユーザの認証情報でログインする
- MFA devices → Register device →　認証アプリ → Next → Show QR code
  - QRコードをアプリで読み取り、認証コードを入力する


## 信頼ポリシーを編集する？
- Condition句でMFA有効化の場合のみ許可とする設定を記述
  - 外部IDp(Azure AD)でユーザを管理している場合はどうなる？
  - Azure AD側でMFA必須にする？
  
```json:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<account-id>:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_<Permission-Sets-Name>"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
              "Bool": {
                "aws:MultiFactorAuthPresent": "true"
              }
            }
        }
    ]
}
```

## AWS CLIの設定/認証情報ファイルを編集？

- configファイル

```sh:
; MFA Test
[profile mfa_test]
region=ap-northeast-1

[profile switch_mfa_test]
source_profile=mfa_test
role_arn=<role-arn>
mfa_serial=<mfa-arn>
```

- credentialsファイル

```sh:
[mfa_test]
aws_access_key_id=<access-key>
aws_secret_access_key=<secret-access-key>
```