@{
    Name = 'GamingDev'

    # Vendor utilities that are not required for Windows, coding, or launching games.
    # Missing services are skipped safely.
    DisableServices = @(
        'cFosSpeedS'
        'EasyTuneEngineService'
        'Gservice'
        'MyService1'
    )

    # Development/emulator services remain installed but start only on demand.
    ManualServices = @(
        'MySQL84'
        'postgresql-x64-14'
        'postgresql-x64-18'
        'pgagent-pg18'
        'MuMuPlayerRemoteService'
    )

    # These services are stopped while applying the gaming-focused profile.
    StopServices = @(
        'cFosSpeedS'
        'EasyTuneEngineService'
        'Gservice'
        'MyService1'
        'MySQL84'
        'postgresql-x64-14'
        'postgresql-x64-18'
        'pgagent-pg18'
        'MuMuPlayerRemoteService'
    )

    Startup = @{
        HKCU = @(
            'Docker Desktop'
            'MuMuPlayerGlobal'
            'GoogleChromeAutoLaunch_*'
            'CometUpdaterTaskUser*'
        )
        HKLM = @(
            'Gigabyte Speed'
        )
    }

    ScheduledTaskPatterns = @(
        '\EasyTune*'
        '\GraphicsCardEngine'
        '\SIV*'
    )

    DevServicePatterns = @(
        'MySQL*'
        'postgresql-*'
        'pgagent-*'
    )

    GameCompatibility = @{
        DeviceNamePatterns = @(
            '*MuMuPlayer*Virtual Display*'
        )
        Services = @(
            'MuMuPlayerRemoteService'
            'SbieSvc'
        )
    }
}
