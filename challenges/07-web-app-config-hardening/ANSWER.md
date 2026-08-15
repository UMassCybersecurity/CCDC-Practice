# Challenge 07 Answer Key — Web App Config Hardening

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`/etc/systemd/system/widgetapp.service` has `User=root`. `/opt/widgetapp/app.py` hardcodes `USERS = {"admin": "admin123"}`. `/etc/nginx/sites-available/widgetapp` has `location /app/ { alias /opt/widgetapp/; autoindex on; }`, exposing the app's source directory.

## Step-by-step fix
`vagrant ssh`, then as root (`sudo -i`):
1. Create a dedicated service account and fix ownership:
   ```
   useradd --system --no-create-home --shell /usr/sbin/nologin widgetapp
   chown -R widgetapp:widgetapp /opt/widgetapp
   ```
2. Edit `/etc/systemd/system/widgetapp.service`, change `User=root` to `User=widgetapp`, then:
   ```
   systemctl daemon-reload
   systemctl restart widgetapp
   ```
3. Edit `/opt/widgetapp/app.py` to remove/replace the default credential (e.g. `USERS = {}` or a new random password), then `systemctl restart widgetapp` again.
4. Edit `/etc/nginx/sites-available/widgetapp`, remove the `location /app/ { ... autoindex on; }` block (or change `autoindex on;` to `autoindex off;` and add `deny all;`), then:
   ```
   nginx -t && systemctl reload nginx
   ```
5. Confirm: `curl http://localhost/` still returns "WidgetCorp App Online"; `curl -X POST -d "username=admin&password=admin123" http://localhost/login` no longer returns `{"status":"ok"}`; `curl http://localhost/app/` no longer shows "Index of".

## Validation
Ran a fresh `vagrant up` on 2026-08-14, confirmed `score_me.sh` showed 1/4 before any fix, applied the steps above verbatim as root, and confirmed a perfect 4/4. Torn down with `vagrant destroy -f` afterward.
