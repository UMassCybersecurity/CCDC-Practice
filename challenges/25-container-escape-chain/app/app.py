import os
import subprocess

from flask import Flask, jsonify, request

app = Flask(__name__)

ADMIN_TOKEN = "changeme123"


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


@app.route("/admin/exec", methods=["POST"])
def admin_exec():
    if request.headers.get("X-Admin-Token") != ADMIN_TOKEN:
        return jsonify(error="unauthorized"), 403

    docker_host = os.environ.get("DOCKER_HOST")
    if not docker_host:
        return jsonify(error="docker control plane not configured"), 501

    cmd = (request.get_json(silent=True) or {}).get("cmd", "ps")
    result = subprocess.run(
        ["docker", "-H", docker_host] + cmd.split(),
        capture_output=True,
        text=True,
        timeout=10,
    )
    return jsonify(stdout=result.stdout, stderr=result.stderr), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
