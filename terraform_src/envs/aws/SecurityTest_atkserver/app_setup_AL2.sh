#!/bin/bash

# gitコマンドをインストール
yum -y update && yum install -y git

# リポジトリをclone
git clone https://github.com/is0356xi/my-aws-account

# Flaskのセットアップ
yum install -y gcc openssl-devel bzip2-devel libffi-devel make zlib-devel readline-devel sqlite-devel xz-devel
curl https://pyenv.run | bash
echo 'export PATH="$HOME//.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
source ~/.bashrc

pyenv install 3.10 && pyenv global 3.10
cd /my-aws-account/SecurityTest/webapp && pip install -r requirements.txt


# appの起動
cd ../cc-sample
python server.py


