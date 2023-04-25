from flask_restful import Resource

from .packages import *
# from .packages import global_conn

import os
import mysql.connector as mysql

class DeleteUsers(Resource):
    def get(self):
        print("!!!!!!! DeleteUsers !!!!!!!")

        #データベースへの接続情報
        host = os.environ['host']
        port = os.environ['port']
        user = os.environ['user']
        password = os.environ['password']
        database = os.environ['database']

        # データベースへの接続
        config = {
            'host': host,
            'port': port,
            'user': user,
            'password': password,
            'database': database  
        }

        # コネクション確立
        conn = mysql.connect(**config)
        print(f'\n!!!!!!!!!!!! MySQL Connection Status: {conn.is_connected()} !!!!!!!!!!!!\n')

        # コネクションが切断されたら再接続
        conn.ping(reconnect=True)

        response = delete_users(connection=conn)
        print(response)

        # 切断処理
        conn.close()

        return response
