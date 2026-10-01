[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Profile,

    [switch]$Apply,
    [switch]$CreateRestorePoint
)

. "$PSScriptRoot\Common.ps1"

$profilePath = (Resolve-Path -LiteralPath $Profile).Path
$settings = Import-PowerShellDataFile -LiteralPath $profilePath

Write-Host "Profile: $($settings.Name)" -ForegroundColor Cyan
Write-Host "Disable services: $($settings.DisableServices -join ', ')"
Write-Host "Manual services: $($settings.ManualServices -join ', ')"
Write-Host "Stop services: $($settings.StopServices -join ', ')"
Write-Host "Scheduled tasks: $($settings.ScheduledTaskPatterns -join ', ')"

if (-not $Apply) {
    Write-Warning 'Preview saja. Tambahkan -Apply untuk membuat backup state dan menerapkan perubahan.'
    return
}

Assert-Administrator

if ($CreateRestorePoint) {
    try {
        Checkpoint-Computer -Description "Before-$($settings.Name)-$(Get-Date -Format yyyyMMdd-HHmmss)" -RestorePointType MODIFY_SETTINGS
    } catch {
        Write-Warning "Restore point tidak dapat dibuat: $($_.Exception.Message)"
    }
}

$stateDir = Get-ToolkitDataPath -Name state
$statePath = Join-Path $stateDir "profile-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$serviceBackup = @()
$startupBackup = @()
$taskBackup = @()

$allServiceNames = @($settings.DisableServices + $settings.ManualServices + $settings.StopServices | Sort-Object -Unique)
foreach ($name in $allServiceNames) {
    $svc = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
    if ($svc) {
        $serviceBackup += [pscustomobject]@{
            Name = $svc.Name
            StartMode = $svc.StartMode
            WasRunning = ($svc.State -eq 'Running')
        }
    }
}

$runPaths = @{
    HKCU = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    HKLM = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
}

foreach ($scope in @('HKCU', 'HKLM')) {
    $path = $runPaths[$scope]
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $item = Get-Item -LiteralPath $path
    $properties = (Get-ItemProperty -LiteralPath $path).PSObject.Properties |
        Where-Object { $_.Name -notmatch '^PS' }

    foreach ($pattern in @($settings.Startup[$scope])) {
        foreach ($property in @($properties | Where-Object { $_.Name -like $pattern })) {
            $startupBackup += [pscustomobject]@{
                Scope = $scope
                Path = $path
                Name = $property.Name
                Value = $property.Value
                Kind = $item.GetValueKind($property.Name).ToString()
            }
        }
    }
}

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue)
foreach ($pattern in @($settings.ScheduledTaskPatterns)) {
    foreach ($task in @($tasks | Where-Object { "$($_.TaskPath)$($_.TaskName)" -like $pattern })) {
        $taskBackup += [pscustomobject]@{
            TaskPath = $task.TaskPath
            TaskName = $task.TaskName
            WasEnabled = [bool]$task.Settings.Enabled
        }
    }
}

$state = [ordered]@{
    CreatedAt = Get-Date
    ComputerName = $env:COMPUTERNAME
    Profile = $profilePath
    Services = @($serviceBackup | Sort-Object Name -Unique)
    Startup = @($startupBackup | Sort-Object Scope, Name -Unique)
    ScheduledTasks = @($taskBackup | Sort-Object TaskPath, TaskName -Unique)
}
Save-Json -Value $state -Path $statePath -Depth 8
Write-Host "Rollback state: $statePath" -ForegroundColor Green

foreach ($name in @($settings.StopServices)) {
    if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($name, 'Stop service')) {
            Stop-Service -Name $name -Force -ErrorAction Continue
        }
    }
}

foreach ($name in @($settings.DisableServices)) {
    if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($name, 'Set service startup to Disabled')) {
            Set-Service -Name $name -StartupType Disabled
        }
    }
}

foreach ($name in @($settings.ManualServices)) {
    if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($name, 'Set service startup to Manual')) {
            Set-Service -Name $name -StartupType Manual
        }
    }
}

foreach ($entry in @($startupBackup)) {
    if ($PSCmdlet.ShouldProcess("$($entry.Scope) Run/$($entry.Name)", 'Disable startup value')) {
        Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction Continue
    }
}

foreach ($entry in @($taskBackup | Where-Object WasEnabled)) {
    if ($PSCmdlet.ShouldProcess("$($entry.TaskPath)$($entry.TaskName)", 'Disable scheduled task')) {
        Disable-ScheduledTask -TaskPath $entry.TaskPath -TaskName $entry.TaskName | Out-Null
    }
}

Write-Host 'Profile selesai diterapkan. Restart disarankan setelah pekerjaan aktif disimpan.' -ForegroundColor Green
