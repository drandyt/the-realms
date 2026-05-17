# tools/close-sessions.ps1
# Project-scope session close. Sends "wrap up" to every idle Claude session
# listed in tools/.sessions-queue.json (this project only).
#
# Called by the human MGR for this project: the MGR calls list_sessions,
# filters to this project's idle sessions, writes the filtered array to
# tools/.sessions-queue.json, then runs this. Queue file deleted on completion.
# (Portfolio-wide equivalent: C:\Dev\Director\tools\close-portfolio.ps1)
#
# Usage:  & "C:\Dev\TheRealms\tools\close-sessions.ps1" [-DryRun]

param([switch]$DryRun)

$queueFile = Join-Path $PSScriptRoot ".sessions-queue.json"

if (-not (Test-Path $queueFile)) {
    Write-Error "No queue file at $queueFile. Run from MGR -- it writes the file first."
    exit 1
}

$sessions = Get-Content $queueFile -Raw | ConvertFrom-Json
$closed   = @()
$skipped  = @()
$failed   = @()

foreach ($s in $sessions) {
    if ($s.isRunning) {
        $skipped += $s.title
        Write-Host "SKIP  $($s.title)  (in-flight)"
        continue
    }

    Write-Host ">> $($s.title)  [$($s.sessionId)]"

    if ($DryRun) {
        $closed += "$($s.title) [dry-run]"
        continue
    }

    $sid = $s.sessionId -replace '^local_', ''
    claude -p "wrap up" -r $sid --permission-mode bypassPermissions 2>&1
    if ($LASTEXITCODE -eq 0) { $closed += $s.title }
    else                     { $failed += $s.title }
}

Write-Host ""
Write-Host "Done. Closed=$($closed.Count)  Skipped=$($skipped.Count)  Failed=$($failed.Count)"
foreach ($t in $closed)  { Write-Host "  OK  $t" }
foreach ($t in $skipped) { Write-Host "  --  $t (in-flight, close manually)" }
foreach ($t in $failed)  { Write-Host "  ERR $t" }

Remove-Item $queueFile -ErrorAction SilentlyContinue
