from flask import Flask, render_template

app = Flask(
    __name__, 
    static_folder='../vul-app/dist/static',
    template_folder='../vul-app/dist'
)

# Blueprintで分割したAPI機能をインポート・登録
from API.api import api_bp
app.register_blueprint(api_bp)


@app.route('/', defaults={'path':''})
@app.route('/<path:path>')
def index(path):
    print(path)
    return render_template('index.html')

if __name__ == "__main__":
    app.run("0.0.0.0")