<?php
echo "POST=", count($_POST), " FILES=", count($_FILES), "\n";
if (isset($_POST['nome'])) echo "nome=", $_POST['nome'], "\n";
if (isset($_FILES['f'])) echo "file=", $_FILES['f']['name'], " type=", $_FILES['f']['type'], " size=", $_FILES['f']['size'], "\n";
$e = error_get_last(); if ($e) echo "LAST_ERROR: ", $e['message'], "\n";
