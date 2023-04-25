import mysql.connector as mysql
import time

def register_user(user_name, password, delay, connection):
    # SQL実行後のステータスを格納
    response = {}

    # データベース操作のためのカーソル生成
    cur = connection.cursor()

    # データ登録のSQL文を作成
    sql = 'INSERT INTO users (user_name, password) VALUES (%s,%s)'

    # SQL文を実行
    try:
        record = (user_name, password)
        print(record)
        cur.execute(sql, record)
        time.sleep(int(delay)) # 指定された秒数遅延させる
        connection.commit()
        
        response['code'] = 200
        response['message'] = 'Registered Your Account.'

    except Exception as e:
        connection.rollback()
        
        response['code'] = 400
        response['message'] = str(e)

    # カーソルをクローズ
    cur.close()
    
    return response

