#!/bin/bash
# Generates the multipart request bodies used by run_tests.sh
D="$(dirname "$0")"
# 1. normal form + file, with an extra header and a duplicated Content-Disposition
printf -- '--XyZ\r\nContent-Disposition: form-data; name="nome"\r\nX-Inutile: abc\r\nContent-Disposition: form-data; name="falso"\r\n\r\nMario\r\n--XyZ\r\nContent-Disposition: form-data; name="f"; filename="a.txt"\r\nContent-Type: text/plain\r\n\r\nciao mondo\r\n--XyZ--\r\n' > "$D/body_normal.txt"
# 2. 3000 parts (more than max_input_vars 1000 + max_file_uploads 20)
{ for i in $(seq 1 3000); do printf -- '--XyZ\r\nContent-Disposition: form-data; name="v%d"\r\n\r\n%d\r\n' $i $i; done; printf -- '--XyZ--\r\n'; } > "$D/body_many.txt"
# 3. session upload progress
printf -- '--XyZ\r\nContent-Disposition: form-data; name="PHP_SESSION_UPLOAD_PROGRESS"\r\n\r\nprova\r\n--XyZ\r\nContent-Disposition: form-data; name="f"; filename="b.txt"\r\nContent-Type: text/plain\r\n\r\ncontenuto file\r\n--XyZ--\r\n' > "$D/body_progress.txt"
