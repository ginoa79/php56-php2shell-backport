@echo off
rem Builds PHP 5.6.40 with the PHP2Shell patch (CVE-2026-109618 / CVE-2026-109619)
rem Same characteristics as the official php-5.6.40-Win32-VC11-x64 package:
rem VC11, x64, thread safe. Rebuilds the core only (php5ts.dll, php.exe,
rem php-cgi.exe): reuse the extension DLLs in ext\ from the official package.
rem
rem Usage: build-windows.bat [deps folder]
rem   deps folder: VC11 x64 deps (libxml2, libiconv, zlib, libmcrypt).
rem   Use libxml2-2.9.4-1 to match the official build, or libxml2-2.9.9.
rem   Default: %BASE%\deps
rem
rem Layout expected (adjust BASE if needed):
rem   %BASE%\php-5.6.40-src   patched sources
rem   %BASE%\php-sdk          php-sdk-binary-tools-20110915

set "BASE=C:\php56fix"
set "DEPS=%~1"
if "%DEPS%"=="" set "DEPS=%BASE%\deps"
set "OBJ=%BASE%\obj-%~n1"
if "%~1"=="" set "OBJ=%BASE%\obj"

call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86_amd64
if errorlevel 1 exit /b 1
set "PATH=%BASE%\php-sdk\bin;%PATH%"

cd /d "%BASE%\php-5.6.40-src"
if errorlevel 1 exit /b 1
if not exist "%OBJ%" mkdir "%OBJ%"

call "%BASE%\php-5.6.40-src\buildconf.bat"
if errorlevel 1 exit /b 1

cscript /nologo configure.js --disable-all --enable-zts --enable-cli --enable-cgi --enable-bcmath --enable-calendar --enable-ctype --with-dom --with-ereg --enable-filter --enable-ftp --enable-hash --with-mhash --with-iconv --enable-json --with-libxml --with-mcrypt=static --with-mysqlnd --enable-odbc --enable-pdo --enable-phar --enable-session --with-simplexml --enable-tokenizer --with-wddx --with-xml --enable-xmlreader --enable-xmlwriter --enable-zip --enable-zlib --with-php-build=%DEPS% --enable-object-out-dir=%OBJ%\
if errorlevel 1 exit /b 1

nmake
if errorlevel 1 exit /b 1
echo BUILD OK - binaries in %OBJ%\Release_TS