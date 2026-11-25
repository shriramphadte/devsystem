@echo off
REM Build fc-python on fc-os
REM Usage: build.bat [PYTHON_VERSION] [OS_VERSION]   (defaults: 3.14 ubuntu26.04)
set PYTHON_VERSION=%1
if "%PYTHON_VERSION%"=="" set PYTHON_VERSION=3.14
set OS_VERSION=%2
if "%OS_VERSION%"=="" set OS_VERSION=ubuntu26.04

docker build --build-arg PYTHON_VERSION=%PYTHON_VERSION% --build-arg OS_VERSION=%OS_VERSION% -t fc-python:%PYTHON_VERSION% "%~dp0."
if errorlevel 1 exit /b 1
echo Image built as fc-python:%PYTHON_VERSION%
