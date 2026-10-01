[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [switch]$RestoreHealth,
    [switch]$SystemFileCheck,
    [switch]$ConfigureCrashDumps,

    [ValidateSet('None', 'Scan', 'ScheduleFix')]
    [string]$DiskAction = 'None',

    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'C'
)

. "$PSScriptRoot\Common.ps1"
Assert-Administrator

if (-not ($RestoreHealth -or $SystemFileCheck -or $ConfigureCrashDumps -or $DiskAction -ne 'None')) {
    throw 'Tidak ada tindakan dipilih. Lihat Get-Help .\Repair-Windows.ps1 -Detailed.'
}

$reports = Get-ToolkitDataPath -Name reports
$logPath = Join-Path $reports "repair-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $logPath | Out-Null

try {
    if ($RestoreHealth -and $PSCmdlet.ShouldProcess('Windows component store', 'DISM RestoreHealth')) {
        & dism.exe /Online /Cleanup-Image /RestoreHealth
        if ($LASTEXITCODE -ne 0) { throw "DISM gagal dengan exit code $LASTEXITCODE" }
    }

    if ($SystemFileCheck -and $PSCmdlet.ShouldProcess('Windows protected system files', 'SFC Scannow')) {
        & sfc.exe /scannow
        if ($LASTEXITCODE -notin @(0, 1, 2)) { throw "SFC gagal dengan exit code $LASTEXITCODE" }
    }

    if ($ConfigureCrashDumps -and $PSCmdlet.ShouldProcess('CrashControl registry', 'Configure kernel and minidump capture')) {
        $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
        Set-ItemProperty -Path $path -Name CrashDumpEnabled -Type DWord -Value 2
        Set-ItemProperty -Path $path -Name AutoReboot -Type DWord -Value 0
        Set-ItemProperty -Path $path -Name LogEvent -Type DWord -Value 1
        Set-ItemProperty -Path $path -Name Overwrite -Type DWord -Value 1
        Write-Host 'Crash dump kernel dan minidump telah dikonfigurasi.' -ForegroundColor Green
    }

    if ($DiskAction -eq 'Scan' -and $PSCmdlet.ShouldProcess("$DriveLetter`:", 'Online filesystem scan')) {
        Repair-Volume -DriveLetter $DriveLetter -Scan
    }

    if ($DiskAction -eq 'ScheduleFix' -and $PSCmdlet.ShouldProcess("$DriveLetter`:", 'Schedule CHKDSK /F at next boot')) {
        & fsutil.exe dirty set "$DriveLetter`:"
        & chkntfs.exe /C "$DriveLetter`:"
        Write-Warning "Repair $DriveLetter`: dijadwalkan. Restart saat siap dan jangan mematikan PC selama CHKDSK."
    }
} finally {
    Stop-Transcript | Out-Null
    Write-Host "Log: $logPath" -ForegroundColor Cyan
}
