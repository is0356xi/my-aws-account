from flask import request
from flask_restful import Resource

from .packages import *
# from .packages import global_conn

import os
import mysql.connector as mysql

class Signup(Resource):
    def post(self):
        print('!!!!!!! SignUp !!!!!!!!')
        
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

        # POSTデータを取得
        body = request.get_json()
        user_name = body['user_name']
        password = body['password']
        delay = body['delay']

        # MySQLの登録処理
        response = register_user(user_name, password, delay, connection=global_conn)
        print(response)

        # 切断処理
        conn.close()

        return response
