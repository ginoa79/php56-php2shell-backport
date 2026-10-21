<?php
ini_set('memory_limit', '8M');
set_error_handler(function(){ echo "ERROR HANDLER CALLED\n"; return true; });
register_shutdown_function(function(){ echo "SHUTDOWN FUNCTION RAN\n"; });
$a = array();
while (true) { $a[] = str_repeat('x', 100000); }
