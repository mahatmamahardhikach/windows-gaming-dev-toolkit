[CmdletBinding()]
param()

$scripts = Join-Path $PSScriptRoot 'scripts'
. "$scripts\Common.ps1"

if (-not (Test-IsAdministrator)) {
    $engine = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
    Start-Process $engine -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`""
    )
    return
}

$profile = Join-Path $PSScriptRoot 'profiles\gaming-dev.psd1'

while ($true) {
    Clear-Host
    Write-Host 'Windows Gaming + Development Toolkit' -ForegroundColor Cyan
    Write-Host '1. Audit read-only'
    Write-Host '2. Repair DISM + SFC'
    Write-Host '3. Scan filesystem C: tanpa offline fix'
    Write-Host '4. Preview profile GamingDev'
    Write-Host '5. Apply profile GamingDev + restore point'
    Write-Host '6. Mode Gaming (stop database dev)'
    Write-Host '7. Mode Coding (start database dev)'
    Write-Host '8. Preview Game Compatibility (MuMu/Sandboxie)'
    Write-Host '9. Apply Game Compatibility'
    Write-Host '10. Restore Game Compatibility terakhir'
    Write-Host '11. Restore profile terakhir'
    Write-Host '0. Keluar'
    $choice = Read-Host 'Pilih'

    try {
        switch ($choice) {
            '1' { & "$scripts\Audit-Windows.ps1" }
            '2' { & "$scripts\Repair-Windows.ps1" -RestoreHealth -SystemFileCheck -Confirm }
            '3' { & "$scripts\Repair-Windows.ps1" -DiskAction Scan -DriveLetter C -Confirm }
            '4' { & "$scripts\Apply-Profile.ps1" -Profile $profile }
            '5' { & "$scripts\Apply-Profile.ps1" -Profile $profile -Apply -CreateRestorePoint -Confirm }
            '6' { & "$scripts\Set-WorkMode.ps1" -Mode Gaming -Profile $profile -Confirm }
            '7' { & "$scripts\Set-WorkMode.ps1" -Mode Coding -Profile $profile -Confirm }
            '8' { & "$scripts\Set-GameCompatibility.ps1" -Mode Gaming -Profile $profile }
            '9' { & "$scripts\Set-GameCompatibility.ps1" -Mode Gaming -Profile $profile -Apply -Confirm }
            '10' { & "$scripts\Set-GameCompatibility.ps1" -Mode Restore -Apply -Confirm }
            '11' { & "$scripts\Restore-Profile.ps1" -Latest -Apply -Confirm }
            '0' { return }
            default { Write-Warning 'Pilihan tidak dikenal.' }
        }
    } catch {
        Write-Error $_
    }

    if ($choice -ne '0') { Read-Host 'Tekan Enter untuk kembali ke menu' | Out-Null }
}
