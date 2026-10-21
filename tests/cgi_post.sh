#!/bin/bash
# usage: cgi_post.sh <php-cgi> <script.php> <body file> [-d options ...]
CGI="$1"; SCRIPT="$2"; BODY="$3"; shift 3
D="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$D/sess"
LEN=$(stat -c %s "$BODY")
REDIRECT_STATUS=1 GATEWAY_INTERFACE=CGI/1.1 REQUEST_METHOD=POST \
SCRIPT_FILENAME="$SCRIPT" SCRIPT_NAME=/t.php \
CONTENT_TYPE="multipart/form-data; boundary=XyZ" CONTENT_LENGTH=$LEN \
HTTP_COOKIE="PHPSESSID=testsession123" \
"$CGI" -n -d session.save_path="$D/sess" "$@" < "$BODY"
echo "[exit code: $?]"
