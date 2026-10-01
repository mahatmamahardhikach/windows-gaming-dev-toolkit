[CmdletBinding()]
param(
    [ValidateRange(1, 365)]
    [int]$Days = 30,

    [string]$OutputPath
)

. "$PSScriptRoot\Common.ps1"

if (-not $OutputPath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutputPath = Join-Path (Get-ToolkitDataPath -Name reports) "audit-$stamp.json"
}

$since = (Get-Date).AddDays(-$Days)

function Get-EventSummary {
    param(
        [string]$LogName,
        [int[]]$Ids,
        [string]$ProviderName,
        [int]$Limit = 100
    )

    $filter = @{ LogName = $LogName; StartTime = $since }
    if ($Ids) { $filter.Id = $Ids }
    if ($ProviderName) { $filter.ProviderName = $ProviderName }

    try {
        @(Get-WinEvent -FilterHashtable $filter -ErrorAction Stop |
            Select-Object -First $Limit |
            ForEach-Object {
                [pscustomobject]@{
                    TimeCreated  = $_.TimeCreated
                    ProviderName = $_.ProviderName
                    Id           = $_.Id
                    Level        = $_.LevelDisplayName
                    Message      = (($_.Message -replace '[\r\n]+', ' ') -replace '\s+', ' ').Trim()
                }
            })
    } catch {
        @()
    }
}

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor
$gpus = @(Get-CimInstance Win32_VideoController | ForEach-Object {
    [pscustomobject]@{
        Name          = $_.Name
        DriverVersion = $_.DriverVersion
        DriverDate    = $_.DriverDate
        AdapterRAMGB  = if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1GB, 2) } else { $null }
    }
})

$disks = @(Get-CimInstance Win32_DiskDrive | ForEach-Object {
    [pscustomobject]@{
        Model            = $_.Model
        FirmwareRevision = $_.FirmwareRevision
        InterfaceType    = $_.InterfaceType
        Status           = $_.Status
        SizeGB           = [math]::Round($_.Size / 1GB, 1)
    }
})

$logicalDisks = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    [pscustomobject]@{
        Drive      = $_.DeviceID
        FileSystem = $_.FileSystem
        SizeGB     = [math]::Round($_.Size / 1GB, 1)
        FreeGB     = [math]::Round($_.FreeSpace / 1GB, 1)
    }
})

$startup = @(Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command)
$thirdPartyAutoServices = @(Get-CimInstance Win32_Service |
    Where-Object {
        $_.StartMode -eq 'Auto' -and
        $_.PathName -notmatch '(?i)\\Windows\\(System32|SysWOW64)|Microsoft'
    } |
    Select-Object Name, DisplayName, State, StartMode, PathName)

$crashControl = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -ErrorAction SilentlyContinue
$pagefileUsage = @(Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue |
    Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage)

$systemEvents = Get-EventSummary -LogName System -Ids @(7, 11, 41, 51, 55, 98, 129, 140, 153, 157, 161, 6008) -Limit 200
$wheaEvents = Get-EventSummary -LogName System -ProviderName 'Microsoft-Windows-WHEA-Logger' -Limit 100
$applicationEvents = Get-EventSummary -LogName Application -Ids @(1000, 1001, 1002) -Limit 200

$report = [ordered]@{
    GeneratedAt = Get-Date
    DaysCovered = $Days
    Elevated = Test-IsAdministrator
    System = [ordered]@{
        Windows = "$($os.Caption) $($os.Version) build $($os.BuildNumber)"
        LastBoot = $os.LastBootUpTime
        Manufacturer = $computer.Manufacturer
        Model = $computer.Model
        RAMGB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        CPU = @($cpu | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors)
        GPU = $gpus
        Disks = $disks
        LogicalDisks = $logicalDisks
        PowerPlan = (& powercfg.exe /getactivescheme | Out-String).Trim()
        Pagefile = $pagefileUsage
        CrashDump = [ordered]@{
            CrashDumpEnabled = $crashControl.CrashDumpEnabled
            DumpFile = $crashControl.DumpFile
            MinidumpDir = $crashControl.MinidumpDir
            AutoReboot = $crashControl.AutoReboot
        }
    }
    Workload = [ordered]@{
        StartupItems = $startup
        ThirdPartyAutomaticServices = $thirdPartyAutoServices
    }
    Events = [ordered]@{
        System = $systemEvents
        WHEA = $wheaEvents
        Application = $applicationEvents
    }
}

Save-Json -Value $report -Path $OutputPath -Depth 10

$bugchecks = @($systemEvents | Where-Object { $_.Id -eq 41 }).Count
$storageSignals = @($systemEvents | Where-Object { $_.ProviderName -match '(?i)ntfs|disk|stor|volmgr' }).Count
$wheaCount = @($wheaEvents).Count

Write-Host "Audit selesai: $OutputPath" -ForegroundColor Green
Write-Host "Kernel-Power entries: $bugchecks"
Write-Host "Storage/NTFS/volmgr signals: $storageSignals"
Write-Host "WHEA entries: $wheaCount"
Write-Host 'Audit tidak mengubah konfigurasi Windows.' -ForegroundColor Cyan
