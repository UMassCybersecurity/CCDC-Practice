from flask import Flask, jsonify, request

app = Flask(__name__)

USERS = {"admin": "admin123"}


@app.route("/")
def index():
    return "WidgetCorp App Online"


@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username")
    password = request.form.get("password")
    if USERS.get(username) == password:
        return jsonify(status="ok"), 200
    return jsonify(status="denied"), 401


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
