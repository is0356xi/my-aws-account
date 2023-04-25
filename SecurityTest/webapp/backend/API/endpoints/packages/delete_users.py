import mysql.connector as mysql

def delete_users(connection):
    # SQL実行後のステータスを格納
    response = {}

    # データベース操作のためのカーソル作成
    cur = connection.cursor()

    # ユーザ削除のSQL文を作成
    sql = 'DELETE FROM users WHERE 1=1'

    try:
        # SQL実行
        cur.execute(sql)
        connection.commit()
        
        response['code'] = 200
        response['message'] = 'Deleted All Users!!!'
    
    except Exception as e:
        connection.rollback()
        
        response['code'] = 400
        response['message'] = str(e)

    # カーソルをクローズ
    cur.close()
    
    return response
