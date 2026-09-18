<?php
// Auto-generated thumbnail cache entry. Regenerated whenever the source
// upload changes; safe to delete, it will be rebuilt on next view.
$src = __DIR__ . '/contest_entry_017.png';
if (!file_exists($src)) {
    http_response_code(404);
    exit;
}
header('Content-Type: image/png');
readfile($src);
