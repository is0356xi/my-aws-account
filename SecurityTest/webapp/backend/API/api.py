from flask import Blueprint
from flask_restful import Api

# 処理クラスをimport
from .endpoints.signup import Signup
from .endpoints.showusers import ShowUsers
from .endpoints.deleteusers import DeleteUsers

# /apiのリクエストに対してapi_featureで処理できるよう設定
api_bp = Blueprint('api_feature', __name__, url_prefix='/api')
api = Api(api_bp)

# 処理クラスをAPIとして登録
api.add_resource(Signup, '/signup') 
api.add_resource(ShowUsers, '/showusers')
api.add_resource(DeleteUsers, '/deleteusers')