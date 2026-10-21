# PHP2Shell fix for PHP 5.6.40 (unofficial backport)

An **unofficial** backport of the fixes for **CVE-2026-109618** and
**CVE-2026-109619** ("PHP2Shell", disclosed 21 October 2026) to **PHP 5.6.40**.

The PHP project fixed these issues in 8.2.35, 8.3.36, 8.4.27 and 8.5.12, and
published source-only backports for 7.4, 8.0 and 8.1. Nothing was published for
5.x, which has been end of life since January 2019. This patch fills that gap
for people who still run 5.6 and cannot upgrade right away.

> [!IMPORTANT]
> **Status: experimental, testing in progress.** Reviews and test reports are
> welcome. Please open an issue.

> [!WARNING]
> - This is **not** an official PHP release. The PHP security team has not reviewed it.
> - PHP 5.6 has many **other** known vulnerabilities that were never fixed. This
>   patch closes PHP2Shell only. It does not make 5.6 safe. Upgrading to a
>   supported PHP version is the only real solution.
> - There is no public, verified exploit to test against. The patch was checked
>   with the regression tests described below, not with a working attack.

## What the patch changes

The patch ports the minimal backport the PHP security team published for 7.4
(branch `PHP-7.4-CVE-2026-109618-109619`, commit `712e60f9`, itself derived from
`01a40e89fb` "Avoid state corruption via bailout"). The 5.6 engine has a
different design, so the patch adapts each change to the 5.6 code.

| Area | File(s) | Change |
|---|---|---|
| Out-of-memory handling (CVE-2026-109618) | `Zend/zend_alloc.c`, `Zend/zend_alloc.h` | `memory_limit` exhaustion, integer overflow during allocation and allocator panics no longer call `zend_error()` + `zend_bailout()` while request state is half initialised. They print the fatal error to stderr and terminate the process with `_exit(1)` (new function `zend_mm_safe_error_ex()`). |
| Same, other call sites | `Zend/zend_operators.c`, `Zend/zend_strtod.c`, `Zend/zend_API.h` | "String size overflow" and `Balloc()` failures use the same safe path. |
| Stale state between requests (CVE-2026-109619) | `main/SAPI.c`, `main/main.c`, `Zend/zend_execute_API.c`, `Zend/zend_llist.c`, `Zend/zend_ptr_stack.c` | Pointers to freed request memory are reset at the end of each request: HTTP auth data, `content_type_dup`, superglobals, user error/exception handlers, `EG(exception)`, the object store, linked lists and pointer stacks. `PG(modules_activated)` is reset as well. |
| Session upload progress | `ext/session/session.c` | Upload progress is **always disabled**, whatever `session.upload_progress.enabled` says (same as upstream). |
| Multipart parsing | `main/rfc1867.c`, `main/main.c` | New ini setting `max_multipart_body_parts` (default `-1` = `max_input_vars + max_file_uploads`). Only `Content-Disposition` and `Content-Type` part headers are kept, and duplicates are ignored. `substring_conf()` uses `size_t`. |

**Extra hardening, not in upstream.** The same "reset after free" treatment is
applied to `SG(rfc1867_uploaded_files)`, `SG(callback_func)` and
`EG(in_autoload)`, which have the same stale pointer pattern in 5.6.

**Not ported, and why.**
- `array_init_singleton()` and the `HT_HASH_RESET` change: they only reduce
  memory use while parsing nested request variables. The 5.6 hash table works
  differently (minimum size 8, buckets allocated lazily), and with this patch an
  out-of-memory condition ends the process anyway.
- The `ZEND_CONCAT` / `ZEND_FAST_CONCAT` VM handler changes: in 5.6,
  concatenation goes through `concat_function()`, which is patched.

## Behaviour changes you should know about

- **When a script exceeds `memory_limit`, the PHP process exits immediately**
  (exit code 1). The fatal error goes to **stderr only**: it is no longer passed
  to `error_log`, and shutdown functions and destructors no longer run.
  - With PHP-FPM or FastCGI, the master or web server starts a new worker.
  - With mod_php, the Apache child process exits and is replaced.
  - The built-in development server (`php -S`) is a single process, so it
    stops completely. Upstream PHP 8 avoids this with a mechanism
    (`UnwindExit`) that does not exist in 5.6. The upstream 7.4 backport has the
    same limitation.
- Session upload progress (`$_SESSION[upload_progress_*]`) no longer works.
- Multipart requests with more parts than `max_multipart_body_parts` are cut off
  with a warning.

## Applying the patch

```sh
# official sources: https://www.php.net/distributions/php-5.6.40.tar.gz
tar xzf php-5.6.40.tar.gz
cd php-5.6.40
patch -p1 < php-5.6.40-php2shell-CVE-2026-109618-CVE-2026-109619.patch
# then build as usual (./configure ... && make)
```

The patch applies cleanly to the official `php-5.6.40.tar.gz` and to the
Windows source package `php-5.6.40-src.zip`.

### Windows build

[`build/build-windows.bat`](build/build-windows.bat) rebuilds `php5ts.dll`,
`php.exe` and `php-cgi.exe` with the same characteristics as the official
`php-5.6.40-Win32-VC11-x64` package (VC11, x64, thread safe, same built-in
extensions). The extension DLLs in `ext\` from the official package are reused
unchanged. Requirements:

- Visual Studio 2012 Express for Windows Desktop (`VS2012_WDX_ENU.iso`, still on
  download.microsoft.com)
- `php-sdk-binary-tools-20110915.zip`, plus the VC11 x64 dependencies
  `libxml2-2.9.9`, `libiconv-1.14`, `zlib-1.2.7.3` and `libmcrypt-2.5.8` from
  https://downloads.php.net/~windows/php-sdk/

## Testing

Tested **on Windows x64 only** (VC11, thread safe, CLI and CGI/FastCGI).
**Linux builds have not been tested.**

**PHP's own test suite** (`Zend/tests`, `tests`, `ext/session/tests`, 2568 tests):

| | passed | failed | skipped |
|---|---|---|---|
| official 5.6.40 | 2495 | 1 | 64 |
| patched 5.6.40 | 2486 | 10 | 64 |

The 9 additional failures are all expected:

- **8 × `ext/session/tests/rfc1867*.phpt`:** these tests check session upload
  progress, which is now disabled.
- **`tests/lang/bug45392.phpt`:** the memory-limit fatal error is still printed,
  but the output layout differs by one blank line.
- `bug66481-win32.phpt` fails on the official build too.

**Scripts in [`tests/`](tests/)** (`bash tests/run_tests.sh <php dir>`):

| Test | official 5.6.40 | patched |
|---|---|---|
| memory exhaustion with a shutdown function | fatal error, then **the shutdown function still runs**, exit 255 | fatal error, process ends at once, exit 1 |
| normal multipart form with extra/duplicate part headers | works | works, same result |
| multipart body with 3000 parts | all parsed, then the variables are truncated | stops at 1020 parts with a warning |
| session upload progress | data written to the session | disabled |

With the patched `php5ts.dll`, the extension DLLs of the official package
(mysql, mysqli, pdo_mysql, curl, gd2, mbstring, openssl, intl, soap and others)
load without errors, and `php -m` lists the same 49 modules as the official
build. The extensions themselves were not tested one by one.

## License

The patch modifies PHP source code and is distributed under the
[PHP License 3.01](LICENSE), like PHP itself. "PHP" is a trademark of the PHP
Group. This project is not affiliated with or endorsed by the PHP Group.
