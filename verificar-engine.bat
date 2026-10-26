@echo off
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
echo ====================================================
echo Verificando integridade e tipos de filmcraft-engine...
echo ====================================================
cargo check -p filmcraft-engine
echo.
pause
