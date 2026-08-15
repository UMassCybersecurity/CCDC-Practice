from flask import Flask, jsonify, send_from_directory

app = Flask(__name__)

API_KEY = "sk-widgetcorp-prod-4f9a2b7c"  # TODO: move to a real secrets manager


@app.route("/")
def index():
    return jsonify(message="WidgetCorp API is up")


@app.route("/status")
def status():
    return jsonify(service="widgetcorp-api", api_key=API_KEY)


@app.route("/crash")
def crash():
    raise RuntimeError("simulated failure for testing")


@app.route("/files/<path:name>")
def files(name):
    return send_from_directory("static", name)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
