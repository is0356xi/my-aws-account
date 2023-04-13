import mysql.connector as mysql

def register_user(user_name, password, connection):
    status = insert_into_user(user_name, password, connection)
    return status

def insert_into_user(user_name, password, connection):
    # SQL実行後のステータスを格納
    status = {}

    # データベース操作のためのカーソル生成
    cur = connection.cursor()

    # データ登録のSQL文を作成
    sql = f'INSERT INTO users (user_name, password) VALUES (%s,%s)'

    # SQL文を実行
    try:
        record = (user_name, password)
        print(record)
        cur.execute(sql, record)
        connection.commit()
        
        status['code'] = 200
        status['message'] = 'Registered Your Account.'

    except Exception as e:
        connection.rollback()
        
        status['code'] = 400
        status['message'] = str(e)

    return status

