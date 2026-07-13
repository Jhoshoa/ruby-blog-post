@echo off
setlocal

where foreman >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing foreman...
    gem install foreman
)

set PORT=%PORT:-3000%

foreman start -f Procfile.dev %*
