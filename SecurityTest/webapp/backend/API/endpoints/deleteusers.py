from flask_restful import Resource

from .packages import *
from .packages import global_conn

class DeleteUsers(Resource):
    def get(self):
        print("!!!!!!! DeleteUsers !!!!!!!")

        response = delete_users(connection=global_conn)
        print(response)

        return response
