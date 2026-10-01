[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Gaming', 'Coding')]
    [string]$Mode,

    [string]$Profile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'profiles\gaming-dev.psd1')
)

. "$PSScriptRoot\Common.ps1"
Assert-Administrator

$settings = Import-PowerShellDataFile -LiteralPath (Resolve-Path -LiteralPath $Profile)
$services = Resolve-ServiceMatches -Patterns @($settings.DevServicePatterns)

if (-not $services) {
    Write-Warning 'Tidak ada service database/dev yang cocok dengan profile.'
    return
}

foreach ($service in $services) {
    if ($Mode -eq 'Gaming') {
        if ($service.Status -ne 'Stopped' -and $PSCmdlet.ShouldProcess($service.Name, 'Stop service for Gaming mode')) {
            Stop-Service -Name $service.Name -Force -ErrorAction Continue
        }
    } else {
        if ($service.Status -ne 'Running' -and $PSCmdlet.ShouldProcess($service.Name, 'Start service for Coding mode')) {
            Start-Service -Name $service.Name -ErrorAction Continue
        }
    }
}

Write-Host "Mode $Mode selesai untuk: $($services.Name -join ', ')" -ForegroundColor Green
