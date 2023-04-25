from flask import request
from flask_restful import Resource

from .packages import *
from .packages import global_conn

class Signup(Resource):
    def post(self):
        print('!!!!!!! SignUp !!!!!!!!')
        
        # POSTデータを取得
        body = request.get_json()
        user_name = body['user_name']
        password = body['password']
        delay = body['delay']

        # MySQLの登録処理
        response = register_user(user_name, password, delay, connection=global_conn)
        print(response)

        return response
