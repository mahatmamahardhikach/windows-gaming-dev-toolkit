function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    if (-not (Test-IsAdministrator)) {
        throw 'Perintah ini membutuhkan PowerShell yang dibuka dengan Run as administrator.'
    }
}

function Get-ToolkitRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Get-ToolkitDataPath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('reports', 'state')]
        [string]$Name
    )

    $path = Join-Path (Get-ToolkitRoot) $Name
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $path
}

function Save-Json {
    param(
        [Parameter(Mandatory)] [object]$Value,
        [Parameter(Mandatory)] [string]$Path,
        [int]$Depth = 8
    )

    $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding utf8
}

function Resolve-ServiceMatches {
    param([string[]]$Patterns)

    $all = @(Get-Service -ErrorAction SilentlyContinue)
    $matches = foreach ($pattern in $Patterns) {
        $all | Where-Object { $_.Name -like $pattern -or $_.DisplayName -like $pattern }
    }
    return @($matches | Sort-Object Name -Unique)
}

function Convert-StartMode {
    param([string]$Mode)

    switch ($Mode) {
        'Auto' { 'Automatic' }
        'Automatic' { 'Automatic' }
        'Manual' { 'Manual' }
        'Disabled' { 'Disabled' }
        default { 'Manual' }
    }
}
