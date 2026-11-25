@echo off
REM Build fc-os, the base image for all friendscolony images
REM Usage: build.bat [OS_NAME] [OS_VERSION]   (defaults: ubuntu 26.04)
set OS_NAME=%1
if "%OS_NAME%"=="" set OS_NAME=ubuntu
set OS_VERSION=%2
if "%OS_VERSION%"=="" set OS_VERSION=26.04

docker build --build-arg OS_NAME=%OS_NAME% --build-arg OS_VERSION=%OS_VERSION% -t fc-os:%OS_NAME%%OS_VERSION% "%~dp0."
if errorlevel 1 exit /b 1
echo Image built as fc-os:%OS_NAME%%OS_VERSION%
