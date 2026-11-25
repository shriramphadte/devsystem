@echo off
REM Trust the friendscolony dev root CA for the current Windows user (once per machine; no container needed)
certutil -addstore -user Root "%~dp0fc-ca\root.crt"
if errorlevel 1 exit /b 1
echo Trusted friendscolony Dev Root CA. Restart the browser.
