@echo off
setlocal

for /f "delims=" %%I in ('git rev-parse --show-toplevel') do set "WORKTREE=%%I"

fvm dart run tool/clone_database.dart --hash-source "%WORKTREE%"
if errorlevel 1 exit /b %errorlevel%

cd /d "%WORKTREE%\apps\auravibes_app"
fvm flutter run -d windows --flavor dev --dart-define=AURAVIBES_SERVER_URL=http://localhost:8080/ "--dart-define=DB_HASH_SOURCE=%WORKTREE%"
