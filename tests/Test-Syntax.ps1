$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failed = $false

Get-ChildItem -LiteralPath $root -Recurse -Filter '*.ps1' | ForEach-Object {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) {
        $failed = $true
        Write-Error "$($_.FullName): $($errors.Message -join '; ')"
    } else {
        Write-Host "OK $($_.FullName)"
    }
}

if ($failed) { exit 1 }
