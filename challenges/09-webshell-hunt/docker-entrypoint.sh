#!/bin/sh
set -e

if [ "$VARIANT" = "redteam" ]; then
    rm -f /var/www/html/uploads/thumb_8f2a.php
fi

exec php -S 0.0.0.0:80 -t /var/www/html
