# 품질 게이트 (PowerShell 판). tool/verify.sh 와 동일한 단계를 수행한다.
# 사용법: powershell -ExecutionPolicy Bypass -File tool/verify.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Step($name, [scriptblock]$body) {
    Write-Host "`n== $name =="
    & $body
    if ($LASTEXITCODE -ne 0) { Write-Host "verify FAILED at: $name"; exit 1 }
}

Step '1/5 format' { dart format --output=none --set-exit-if-changed lib test tool }
Step '2/5 analyze' { flutter analyze --fatal-infos --fatal-warnings }
Step '3/5 architecture' { dart run tool/check_architecture.dart }
Step '4/5 balance sync' {
    $env:PYTHONIOENCODING = 'utf-8'
    python -c "import openpyxl" 2>$null
    if ($LASTEXITCODE -eq 0) { python tool/balance/export_balance.py --check }
    else { Write-Host 'skip (python/openpyxl 없음)'; $global:LASTEXITCODE = 0 }
}
Step '5/5 test' { flutter test }
Write-Host "`n== info: spec sync =="
python tool/spec/spec_sync.py
$global:LASTEXITCODE = 0

Write-Host "`nverify PASSED"
