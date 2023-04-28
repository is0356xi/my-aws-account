#!/bin/bash

# 外部から注入された変数をスクリプト内で読み込み
vars=${vars}

# MySQLコマンドのインストール
rpm -Uvh http://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
dnf module disable mysql
dnf install mysql-community-server -y
systemctl enable mysqld
systemctl start mysqld

 