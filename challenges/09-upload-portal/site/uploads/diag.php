<?php
// Left over from chasing the "disk full" ticket last month. Reports free
// space on the uploads volume. Nobody's gotten around to removing it.
header('Content-Type: text/plain');
system('df -h ' . escapeshellarg(__DIR__));
