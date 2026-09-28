@echo off
setlocal

for /f "delims=" %%I in ('git rev-parse --show-toplevel') do set "WORKTREE=%%I"

cd /d "%WORKTREE%\apps\auravibes_app"
fvm flutter run -d windows --flavor dev --dart-define=AURAVIBES_SERVER_URL=http://localhost:8080/ "--dart-define=DB_HASH_SOURCE=%WORKTREE%"
