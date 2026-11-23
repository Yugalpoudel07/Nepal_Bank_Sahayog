# start-backend.ps1
# Starts the Nepal Bank Sahayak API for public use through Tailscale Funnel. Run it by hand, e.g. in a
# VS Code terminal:   powershell -ExecutionPolicy Bypass -File deploy\start-backend.ps1
# Stop it with Ctrl+C. Logs are shown in the terminal.

$ErrorActionPreference = "Stop"
$backend = (Resolve-Path (Join-Path $PSScriptRoot "..\backend")).Path

# The website's address (Cloudflare Pages) is read from deploy\allowed-origin.txt, so it can be
# changed without editing backend\.env. Values set here override the ones in .env.
$originFile = Join-Path $PSScriptRoot "allowed-origin.txt"
$origins = "http://localhost:5173"
if (Test-Path $originFile) {
    $site = (Get-Content $originFile -Raw).Trim().TrimEnd("/")
    if ($site) { $origins = "$site,$origins" }
}
$env:ALLOWED_ORIGINS = $origins
$env:AUTO_REBUILD_INDEX = "false"   # skip the slow index check at start-up (rebuild by hand after new circulars)

Set-Location $backend
# One process only: conversation memory, the rate limiter and the embedding model live in-process.
& (Join-Path $backend ".venv\Scripts\uvicorn.exe") app.main:app --host 127.0.0.1 --port 8000 `
    --proxy-headers --forwarded-allow-ips 127.0.0.1
