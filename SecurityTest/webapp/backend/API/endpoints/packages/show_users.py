import mysql.connector as mysql

def show_users(connection):
    # SQL実行後のステータスを格納
    response = {}

    # データベース操作のためのカーソル作成
    cur = connection.cursor()

    # ユーザ検索のSQL文を作成
    sql = 'SELECT user_name FROM users WHERE 1=1'

    try:
        # SQL実行
        cur.execute(sql)
        
        # 結果の取り出し
        results = cur.fetchall()
        user_list = [{"name":row[0]} for row in results]

        # カーソルをクローズ
        cur.close()

        return user_list
    
    except Exception as e:
        connection.rollback()
        
        response['code'] = 400
        response['message'] = str(e)

        # カーソルをクローズ
        cur.close()
        
        return response
