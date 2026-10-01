[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$StatePath,
    [switch]$Latest,
    [switch]$Apply
)

. "$PSScriptRoot\Common.ps1"

if ($Latest) {
    $StatePath = Get-ChildItem -LiteralPath (Get-ToolkitDataPath -Name state) -Filter 'profile-*.json' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $StatePath) { throw 'Berikan -StatePath atau gunakan -Latest.' }
$resolved = (Resolve-Path -LiteralPath $StatePath).Path
$state = Get-Content -Raw -LiteralPath $resolved | ConvertFrom-Json

Write-Host "State: $resolved" -ForegroundColor Cyan
Write-Host "Services: $(@($state.Services).Count), startup: $(@($state.Startup).Count), tasks: $(@($state.ScheduledTasks).Count)"

if (-not $Apply) {
    Write-Warning 'Preview saja. Tambahkan -Apply untuk rollback.'
    return
}

Assert-Administrator

foreach ($entry in @($state.Services)) {
    if (Get-Service -Name $entry.Name -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($entry.Name, "Restore startup mode $($entry.StartMode)")) {
            Set-Service -Name $entry.Name -StartupType (Convert-StartMode $entry.StartMode)
            if ($entry.WasRunning) { Start-Service -Name $entry.Name -ErrorAction Continue }
        }
    }
}

foreach ($entry in @($state.Startup)) {
    if ($PSCmdlet.ShouldProcess("$($entry.Scope) Run/$($entry.Name)", 'Restore startup value')) {
        if (-not (Test-Path -LiteralPath $entry.Path)) { New-Item -Path $entry.Path -Force | Out-Null }
        New-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $entry.Value -PropertyType $entry.Kind -Force | Out-Null
    }
}

foreach ($entry in @($state.ScheduledTasks | Where-Object WasEnabled)) {
    if ($PSCmdlet.ShouldProcess("$($entry.TaskPath)$($entry.TaskName)", 'Enable scheduled task')) {
        Enable-ScheduledTask -TaskPath $entry.TaskPath -TaskName $entry.TaskName | Out-Null
    }
}

Write-Host 'Rollback selesai.' -ForegroundColor Green
