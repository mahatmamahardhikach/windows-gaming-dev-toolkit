[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Gaming', 'Restore')]
    [string]$Mode,

    [string]$Profile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'profiles\gaming-dev.psd1'),
    [string]$StatePath,
    [switch]$Apply
)

. "$PSScriptRoot\Common.ps1"
Assert-Administrator

$stateDir = Get-ToolkitDataPath -Name state

if ($Mode -eq 'Restore') {
    if (-not $StatePath) {
        $StatePath = Get-ChildItem -LiteralPath $stateDir -Filter 'game-compat-*.json' |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $StatePath) { throw 'Tidak ada state Game Compatibility untuk di-restore.' }

    $state = Get-Content -Raw -LiteralPath (Resolve-Path -LiteralPath $StatePath) | ConvertFrom-Json
    Write-Host "Restore devices: $(@($state.Devices).Count); services: $(@($state.Services).Count)" -ForegroundColor Cyan
    if (-not $Apply) { Write-Warning 'Preview saja. Tambahkan -Apply untuk restore.'; return }

    foreach ($device in @($state.Devices | Where-Object WasEnabled)) {
        if ($PSCmdlet.ShouldProcess($device.FriendlyName, 'Enable PnP device')) {
            Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Continue
        }
    }
    foreach ($service in @($state.Services)) {
        if (Get-Service -Name $service.Name -ErrorAction SilentlyContinue) {
            if ($PSCmdlet.ShouldProcess($service.Name, 'Restore service state')) {
                Set-Service -Name $service.Name -StartupType (Convert-StartMode $service.StartMode)
                if ($service.WasRunning) { Start-Service -Name $service.Name -ErrorAction Continue }
            }
        }
    }
    Write-Host 'Game Compatibility state telah di-restore.' -ForegroundColor Green
    return
}

$settings = Import-PowerShellDataFile -LiteralPath (Resolve-Path -LiteralPath $Profile)
$compat = $settings.GameCompatibility
$displayDevices = @(Get-PnpDevice -Class Display -ErrorAction SilentlyContinue)
$targets = foreach ($pattern in @($compat.DeviceNamePatterns)) {
    $displayDevices | Where-Object { $_.FriendlyName -like $pattern }
}
$targets = @($targets | Sort-Object InstanceId -Unique)
$services = @(foreach ($name in @($compat.Services)) {
    Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
})

Write-Host "Target devices: $($targets.FriendlyName -join ', ')" -ForegroundColor Cyan
Write-Host "Target services: $($services.Name -join ', ')" -ForegroundColor Cyan
Write-Warning 'Ini adalah uji A/B kompatibilitas, bukan bukti bahwa emulator atau Sandboxie merupakan akar crash.'

if (-not $Apply) { Write-Warning 'Preview saja. Tambahkan -Apply untuk menonaktifkan target sementara.'; return }

$statePath = Join-Path $stateDir "game-compat-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$state = [ordered]@{
    CreatedAt = Get-Date
    Devices = @($targets | ForEach-Object {
        [pscustomobject]@{
            FriendlyName = $_.FriendlyName
            InstanceId = $_.InstanceId
            WasEnabled = ($_.Status -eq 'OK')
        }
    })
    Services = @($services | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            StartMode = $_.StartMode
            WasRunning = ($_.State -eq 'Running')
        }
    })
}
Save-Json -Value $state -Path $statePath -Depth 6

foreach ($device in $targets) {
    if ($PSCmdlet.ShouldProcess($device.FriendlyName, 'Disable PnP device')) {
        Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction Continue
    }
}

foreach ($service in $services) {
    if ($PSCmdlet.ShouldProcess($service.Name, 'Stop and set service to Manual')) {
        Stop-Service -Name $service.Name -Force -ErrorAction Continue
        Set-Service -Name $service.Name -StartupType Manual
    }
}

Write-Host "Game Compatibility mode aktif. Rollback state: $statePath" -ForegroundColor Green
