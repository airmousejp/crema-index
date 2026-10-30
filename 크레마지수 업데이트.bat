@echo off


cd /d "%~dp0"


echo Updating Crema Index data...


powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-data.ps1"


start "" "%~dp0index.html"


