@echo off
REM Build fc-postgres (PostgreSQL + pgAdmin) on fc-os
REM Usage: build.bat [PG_VERSION] [OS_VERSION]   (defaults: 18 ubuntu26.04)
set PG_VERSION=%1
if "%PG_VERSION%"=="" set PG_VERSION=18
set OS_VERSION=%2
if "%OS_VERSION%"=="" set OS_VERSION=ubuntu26.04

docker build --build-arg PG_VERSION=%PG_VERSION% --build-arg OS_VERSION=%OS_VERSION% -t fc-postgres:%PG_VERSION% "%~dp0."
if errorlevel 1 exit /b 1
echo Image built as fc-postgres:%PG_VERSION%
