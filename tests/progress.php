<?php
session_start();
$k = ini_get('session.upload_progress.prefix') . 'prova';
echo "upload_progress_in_session=", (isset($_SESSION[$k]) ? 'YES' : 'NO'), "\n";
