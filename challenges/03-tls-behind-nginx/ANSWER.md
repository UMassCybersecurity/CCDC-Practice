# Challenge 03 Answer Key — TLS Behind Nginx

**DO NOT READ BEFORE ATTEMPTING THE CHALLENGE**

## What's broken / planted
`edge/default.conf` ships with a plain-HTTP `server` block on port 80 that proxies to the backend, plus a second `server` block on 443 that already references the provided cert/key but restricts `ssl_protocols` to the deprecated `TLSv1 TLSv1.1`. There is no redirect off plain HTTP.

## Step-by-step fix
1. Edit `edge/default.conf`:
   - Replace the port-80 `server` block's `location /` with a redirect.
   - Change `ssl_protocols TLSv1 TLSv1.1;` to `ssl_protocols TLSv1.2 TLSv1.3;` in the 443 block.

   End state:
   ```nginx
   server {
       listen 80;
       server_name widgetcorp.local;
       return 301 https://$host:8143$request_uri;
   }

   server {
       listen 443 ssl;
       server_name widgetcorp.local;

       ssl_certificate     /etc/nginx/certs/server.crt;
       ssl_certificate_key /etc/nginx/certs/server.key;
       ssl_protocols TLSv1.2 TLSv1.3;

       location / {
           proxy_pass http://backend:80;
           proxy_set_header Host $host;
       }
   }
   ```
2. Apply it without a restart: `docker compose exec edge nginx -s reload`
3. Confirm: `curl -sk https://localhost:8143/` returns "Backend online"; `curl -I http://localhost:8100/` returns a 301.

## Validation
Ran a fresh `docker compose up -d --build` on 2026-08-14, confirmed `score_me.sh` showed 0/3 against the shipped (broken) config, edited `edge/default.conf` on the host exactly as above, reloaded, and confirmed `score_me.sh` then showed 3/3. Torn down with `docker compose down -v`.

Note: the original build bind-mounted a single file (`./edge/nginx.conf:/etc/nginx/conf.d/default.conf`) rather than a directory. Docker pins a single-file bind mount to the file's inode at mount time; an editor that saves atomically (write-new-file-then-rename — common in many editors, including the one used here) replaces the inode, so the container keeps serving the old content forever after the first host edit, even though `cat`-ing the file on the host shows the new version. Fixed by mounting the `edge/` directory instead (`./edge:/etc/nginx/conf.d`) and renaming `nginx.conf` to `default.conf` inside it — directory bind mounts follow path lookups, not pinned inodes, so host edits (including atomic-save ones) show up on the next `nginx -s reload` as expected. Re-verified clean after the fix.
