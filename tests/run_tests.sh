#!/bin/bash
# usage: run_tests.sh <dir containing php(.exe) and php-cgi(.exe)>
P="$1"; D="$(cd "$(dirname "$0")" && pwd)"
PHP="$P/php"; CGI="$P/php-cgi"; [ -f "$PHP.exe" ] && PHP="$PHP.exe" && CGI="$CGI.exe"
bash "$D/make_bodies.sh"
filter() { grep -v "^X-Powered\|^Content-type\|^Set-Cookie\|^Expires\|^Cache\|^Pragma\|^$"; }
echo "== 1. memory exhaustion"; "$PHP" -n "$D/oom.php" 2>&1 | tail -3; echo "[exit code: ${PIPESTATUS[0]}]"
echo "== 2. normal multipart form";  bash "$D/cgi_post.sh" "$CGI" "$D/post.php" "$D/body_normal.txt" | filter
echo "== 3. 3000 multipart parts";   bash "$D/cgi_post.sh" "$CGI" "$D/post.php" "$D/body_many.txt" | filter
echo "== 4. session upload progress"; rm -f "$D"/sess/sess_testsession123
bash "$D/cgi_post.sh" "$CGI" "$D/progress.php" "$D/body_progress.txt" -d session.upload_progress.enabled=1 -d session.upload_progress.cleanup=0 | filter
