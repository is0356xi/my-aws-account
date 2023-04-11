#!/bin/bash

# 外部から注入された変数をスクリプト内で読み込み
$vars=${vars}

# SSMエージェントのインストール・起動
REGION_NAME=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/.$//')
dnf install -y "https://s3.$REGION_NAME.amazonaws.com/amazon-ssm-$REGION_NAME/latest/linux_amd64/amazon-ssm-agent.rpm"
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent