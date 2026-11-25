@echo off
REM Create the friendscolony dev root CA (fc-ca\root.crt + root.key) that every project's Caddy proxy signs with
REM Run once. root.key is a secret: it is git-ignored and only mounted into proxy containers, never baked into an image.
SET CA_DIR=%~dp0fc-ca
IF EXIST "%CA_DIR%\root.key" (
    echo %CA_DIR%\root.key already exists. Delete fc-ca\root.crt and root.key first to make a new CA.
    exit /b 1
)
IF NOT EXIST "%CA_DIR%" mkdir "%CA_DIR%"

docker run --rm -v "%CA_DIR%:/ca" fc-caddy:2.10.2 openssl req -x509 -new -nodes ^
    -newkey ec -pkeyopt ec_paramgen_curve:P-256 ^
    -keyout /ca/root.key -out /ca/root.crt -days 3650 -sha256 ^
    -subj "/O=friendscolony/CN=friendscolony Dev Root CA" ^
    -addext "basicConstraints=critical,CA:TRUE" ^
    -addext "keyUsage=critical,keyCertSign,cRLSign" ^
    -addext "subjectKeyIdentifier=hash"
if errorlevel 1 exit /b 1
echo Created %CA_DIR%\root.crt and root.key. Trust it once with trust-ca.bat.
