@echo off
REM Build fc-caddy on fc-os
REM Usage: build.bat [CADDY_VERSION] [OS_VERSION]   (defaults: 2.10.2 ubuntu26.04)
set CADDY_VERSION=%1
if "%CADDY_VERSION%"=="" set CADDY_VERSION=2.10.2
set OS_VERSION=%2
if "%OS_VERSION%"=="" set OS_VERSION=ubuntu26.04

docker build --build-arg CADDY_VERSION=%CADDY_VERSION% --build-arg OS_VERSION=%OS_VERSION% -t fc-caddy:%CADDY_VERSION% "%~dp0."
if errorlevel 1 exit /b 1
echo Image built as fc-caddy:%CADDY_VERSION%
