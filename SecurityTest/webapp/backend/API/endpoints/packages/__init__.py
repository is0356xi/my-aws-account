from .register_user import *
from .show_users import *
from .delete_users import *

__all__ = [
    'register_user',
    'show_users',
    'delete_users',
]

# データベースへの接続処理
# import os
# import mysql.connector as mysql

# #データベースへの接続情報
# host = os.environ['host']
# port = os.environ['port']
# user = os.environ['user']
# password = os.environ['password']
# database = os.environ['database']

# ハードコーディングする場合
# host = 'host'
# port = 'port'
# user = 'user'
# password = 'password'
# database = 'database'

# config = {
#     'host': host,
#     'port': port,
#     'user': user,
#     'password': password,
#     'database': database  
# }

# # コネクション確立
# conn = mysql.connect(**config)
# print(f'\n!!!!!!!!!!!! MySQL Connection Status: {conn.is_connected()} !!!!!!!!!!!!\n')

# # コネクションが切断されたら再接続
# conn.ping(reconnect=True)

# # パッケージ内のモジュールが使用できるようにグローバル用変数に格納
# global_conn = conn