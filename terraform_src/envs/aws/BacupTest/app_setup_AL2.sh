#!/bin/bash

# gitコマンドをインストール
yum -y update && yum install -y git

# リポジトリをclone
git clone https://github.com/is0356xi/my-aws-account
cd /my-aws-account/SecurityTest/webapp

# Vue.jsのセットアップ
yum install -y nodejs npm
npm install -g npm@8.19.3

cd vul-app
npm install && npm run build


# Flaskのセットアップ
yum install -y gcc openssl-devel bzip2-devel libffi-devel make zlib-devel readline-devel sqlite-devel xz-devel
curl https://pyenv.run | bash
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
source ~/.bashrc

pyenv install 3.10 && pyenv global 3.10
cd /my-aws-account/SecurityTest/webapp && pip install -r requirements.txt


# 外部から注入された変数をスクリプト内で読み込み
external_vars=${vars}

# 'を"に置換 (json文字列として扱う)
vars=$(echo $external_vars | sed "s/'/\"/g")

# appの起動
cd /my-aws-account/SecurityTest/webapp/backend
yum install jq -y

export host=$(echo $vars | jq -r '.host')
export port=$(echo $vars | jq -r '.port')
export user=$(echo $vars | jq -r '.user')
export password=$(echo $vars | jq -r '.password')
export database=$(echo $vars | jq -r '.database')

echo $port $user

python main.py


