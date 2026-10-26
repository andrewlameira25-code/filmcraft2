@echo off
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
echo ====================================================
echo Iniciando FilmCraft em Portugues do Brasil (pt-BR)...
echo ====================================================
cargo run --release -p filmcraft -- --lang pt-br
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Ocorreu um erro ao executar o FilmCraft.
    pause
)
