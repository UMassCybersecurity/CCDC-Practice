# Challenge 05 Answer Key — Container Secrets Leak

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`app/app.py` ships with `app.run(debug=True)` (leaks tracebacks on `/crash`), a hardcoded `API_KEY` echoed verbatim by `/status`, and a `/files/<path:name>` route that serves anything under `static/` — including `static/.env`, which contains fake secrets (`DB_PASSWORD`, `STRIPE_SECRET`).

## Step-by-step fix
Edit `app/app.py`:
1. Change `app.run(host="0.0.0.0", port=5000, debug=True)` to `debug=False`.
2. Stop echoing the raw key on `/status` — return whether it's configured instead of its value (or just drop the field). Read it from an env var rather than a literal so it's not baked into the image either:
   ```python
   API_KEY = os.environ.get("API_KEY", "")

   @app.route("/status")
   def status():
       return jsonify(service="widgetcorp-api", api_key_configured=bool(API_KEY))
   ```
3. Reject dotfiles in `/files/<path:name>` before calling `send_from_directory`:
   ```python
   @app.route("/files/<path:name>")
   def files(name):
       if os.path.basename(name).startswith("."):
           abort(404)
       return send_from_directory("static", name)
   ```
4. Rebuild: `docker compose up -d --build` (the app isn't bind-mounted, so a plain restart won't pick up the change).

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `score_me.sh` showed 1/4 against the shipped (broken) `app.py`. Applied the fix above, rebuilt with `docker compose up -d --build`, and confirmed `score_me.sh` then showed 4/4. Torn down with `docker compose down -v`.
