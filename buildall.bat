@echo off
REM Build every shared friendscolony image, base first
call "%~dp0fc-os\build_ubuntu_26.bat" || exit /b 1
call "%~dp0fc-python\build3.14.bat" || exit /b 1
call "%~dp0fc-nodejs\build22.22.bat" || exit /b 1
call "%~dp0fc-postgres\build18.bat" || exit /b 1
call "%~dp0fc-caddy\build2.10.2.bat" || exit /b 1
echo All shared images built
