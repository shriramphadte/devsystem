@echo off
REM Build fc-nodejs on fc-os
REM Usage: build.bat [NODEJS_VERSION] [OS_VERSION]   (defaults: 22.22 ubuntu26.04)
REM NODEJS_VERSION is the tag; the version installed is the one the Ubuntu version ships
set NODEJS_VERSION=%1
if "%NODEJS_VERSION%"=="" set NODEJS_VERSION=22.22
set OS_VERSION=%2
if "%OS_VERSION%"=="" set OS_VERSION=ubuntu26.04

docker build --build-arg NODEJS_VERSION=%NODEJS_VERSION% --build-arg OS_VERSION=%OS_VERSION% -t fc-nodejs:%NODEJS_VERSION% "%~dp0."
if errorlevel 1 exit /b 1
echo Image built as fc-nodejs:%NODEJS_VERSION%
