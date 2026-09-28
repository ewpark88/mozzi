# 밸런스 시트 편집기 (Excel COM). openpyxl 로 저장하면 수식 캐시 값이 사라지므로
# 시트 수정은 반드시 이 스크립트로 한다. 규칙: docs/CODING_RULES.md §10
#
# 사용법: powershell -ExecutionPolicy Bypass -File tool/balance/xlsx_edit.ps1 -EditsJson edits.json
#   edits.json = [{"sheet":"진행 시뮬","cell":"A2","value":"..."}, ...]
# 적용 후: python tool/balance/export_balance.py 로 JSON·fixture 재생성, docs/SPEC_CHANGELOG.md 기록.
param(
    [Parameter(Mandatory = $true)][string]$EditsJson
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
# PowerShell 5.1 은 BOM 없는 스크립트를 ANSI 로 읽으므로 한글 파일명을 리터럴로 쓰지 않는다.
$xlsx = (Get-ChildItem -LiteralPath $root -Filter '*.xlsx' | Select-Object -First 1).FullName
if (-not $xlsx) { throw 'balance xlsx not found' }
$edits = Get-Content -Raw -Encoding UTF8 $EditsJson | ConvertFrom-Json

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
    $wb = $excel.Workbooks.Open($xlsx)
    foreach ($e in $edits) {
        # 없는 시트면 맨 뒤에 새로 만든다
        $ws = $null
        foreach ($s in $wb.Worksheets) { if ($s.Name -eq $e.sheet) { $ws = $s } }
        if ($null -eq $ws) {
            $ws = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
            $ws.Name = $e.sheet
        }
        # PowerShell COM 어댑터는 첫 대입의 타입(문자열)을 캐시해 이후 숫자 대입이 실패한다.
        # InvokeMember 로 직접 설정하고, 숫자는 Excel 이 받는 double 로 넘긴다.
        $v = $e.value
        if ($v -is [int] -or $v -is [long] -or $v -is [decimal]) { $v = [double]$v }
        $range = $ws.Range($e.cell)
        # "=" 로 시작하는 문자열은 수식으로 넣는다 (Formula 속성)
        $prop = if ($v -is [string] -and $v.StartsWith('=')) { 'Formula' } else { 'Value2' }
        [void]$range.GetType().InvokeMember($prop, [System.Reflection.BindingFlags]::SetProperty, $null, $range, @($v))
    }
    $excel.CalculateFull()
    $wb.Save()
    $wb.Close($false)
    Write-Host "applied $($edits.Count) edit(s)"
}
finally {
    $excel.Quit()
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
}
