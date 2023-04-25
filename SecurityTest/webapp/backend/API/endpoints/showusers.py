from flask_restful import Resource

from .packages import *
from .packages import global_conn

class ShowUsers(Resource):
    def get(self):
        print("!!!!!!! ShowUsers !!!!!!!")

        response = show_users(connection=global_conn)
        print(response)

        return response
