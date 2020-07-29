<#
///////////////////////////////////
NVIDIA Auto Power Limit by Lulech23
///////////////////////////////////

What's new:
* Initial public release

To-do:
* Add a GUI, maybe
#>

<#
INITIALIZATION
#>

<# Force run as admin #>
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit 
}

<# Version... obviously #>
$version = "1.0.0"
$ok = $true


<#
SHOW VERSION
#>

<# Ooo, shiny! #>
Write-Host "`n                                                   " -BackgroundColor Green -NoNewline
Write-Host "`n NVIDIA Auto Power Limit Version $version by Lulech23 " -NoNewline -BackgroundColor Green -ForegroundColor White
Write-Host "`n                                                   " -BackgroundColor Green

<# About #>
Write-Host "`nThis script will generate a separate PowerShell script and Windows scheduled task to "
Write-Host "automatically limit GPU power draw any time the GPU is connected. You will also be able "
Write-Host "to edit the generated script to add additional actions to perform."

Write-Host "`nIf you don't like something, running this script again will overwrite previous settings.`n" -ForegroundColor Yellow

Read-Host "Press ENTER to continue"


<#
GET PATH
#>

Write-Host "Enter the folder where you'd like to save your customized script (e.g. `"C:\NVIDIA\`")." -ForegroundColor Yellow
Write-Host "If the folder does not exist, it will be created." -ForegroundColor Yellow

Write-Host "`nWARNING: The generated script path must be its permanent location!`n" -ForegroundColor Red

$path = Read-Host "Enter script folder"

<# Create output folder, if it doesn't exist #>
$path = $path.Replace("`"", "")
if (!(Test-Path "$path")) {
    New-Item -ItemType Directory -Force -Path "$path" | Out-Null
}
$path = Resolve-Path "$path"


<#
GET GPU
#>

Write-Host "`nWe will now get a list of all NVIDIA devices on this PC. Find your GPU and enter it " -ForegroundColor Yellow
Write-Host "on the next screen." -ForegroundColor Yellow

Write-Host "`nWARNING: The GPU name must be input EXACTLY as it appears in the list!`n" -ForegroundColor Red

Read-Host "Press ENTER to continue"

Get-PnpDevice | Out-String -Stream | Select-String NVIDIA

Write-Host "`n"

$gpu = Read-Host "Enter GPU name"


<#
GET POWER LIMIT
#>

if (!(Test-Path "$env:SystemRoot\System32\nvidia-smi.exe")) {
    Write-Host "`nError: NVIDIA SMI utility not found! Please reinstall or update your NVIDIA drivers." -ForegroundColor Red
    Write-Host "`nOperation cancelled.`n" -ForegroundColor Green
    $ok = $false
}

if ($ok) {
    Write-Host "`nYour GPU's current power limit is:`n" -ForegroundColor Cyan
    & "$env:SystemRoot\System32\nvidia-smi.exe" --query-gpu=power.limit --format=csv

    Write-Host "`nYour GPU's minimum and maximum power limit are:`n" -ForegroundColor Cyan
    & "$env:SystemRoot\System32\nvidia-smi.exe" --query-gpu=power.min_limit,power.max_limit --format=csv

    Write-Host "`nPlease enter the desired power limit within the range above, as a number only (e.g. 150).`n" -ForegroundColor Yellow

    $pl = Read-Host "Enter power limit"
}


<#
CONFIRMATION
#>

if ($ok) {
    Write-Host "`nWe will now generate a script in `"$path`"" -ForegroundColor Magenta
    Write-Host "to set the power limit for $gpu to $pl W." -ForegroundColor Magenta

    Write-Host "`nA scheduled task will be created for $env:UserDomain\$env:UserName to automatically " -ForegroundColor Magenta
    Write-Host "run when the GPU is connected. You may be prompted to enter your password.`n" -ForegroundColor Magenta

    $confirm = Read-Host "Continue? [Y/N]"

    switch -regex ($confirm) {
        "N|n" {
            Write-Host "`nOperation cancelled.`n" -ForegroundColor Green
            $ok = $false
        }
        Default {
            Write-Host "`nWriting files...`n" -ForegroundColor Green
            $ok = $true
        }
    }
}


<#
CREATE SCRIPT
#>

if ($ok) {
    <# Delete existing script, if any #>
    if (Test-Path "$path\powerlimit.ps1") {
        Remove-Item -Force -Path "$path\powerlimit.ps1" | Out-Null
    }

    <# Write scheduled task to folder #>
    Set-Content -Path "$path\powerlimit.ps1" -Value @"
Register-WmiEvent -Class Win32_DeviceChangeEvent -SourceIdentifier graphicsCardChanged
do {
    `$newEvent = Wait-Event -SourceIdentifier graphicsCardChanged

    `$eventType = `$newEvent.SourceEventArgs.NewEvent.EventType

    `$eventCondition = (Get-PnpDevice | where {($_.friendlyname) -like "$gpu" -and ($_.status) -like "Ok"}) -ne `$null

    if (`$eventType -eq 2 -and `$eventCondition) {
        <# ADD GPU CONNECT ACTIONS HERE #>
        & "`$env:SystemRoot\System32\nvidia-smi.exe" --power-limit=$pl
        <# END GPU CONNECT ACTIONS #>
    }

    Remove-Event -SourceIdentifier graphicsCardChanged
} while (1-eq1) #Loop until next event
Unregister-Event -SourceIdentifier graphicsCardChanged
"@

    <# Apply power limit #>
    & "`$env:SystemRoot\System32\nvidia-smi.exe" --power-limit=$pl
}


<#
CREATE SCHEDULED TASK
#>

if ($ok) {
    <# Get user SID for scheduled task #>
    $usr = New-Object System.Security.Principal.NTAccount("$env:UserDomain", "$env:UserName")
    $env:UserSID = $usr.Translate([System.Security.Principal.SecurityIdentifier]).Value

    <# Delete existing task, if any #>
    if (Test-Path "$path\powerlimit.xml") {
        Remove-Item -Force -Path "$path\powerlimit.xml" | Out-Null
    }

    <# Write scheduled task to folder #>
    Set-Content -Path "$path\powerlimit.xml" -Value @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
    <RegistrationInfo>
        <Date>2019-12-11T12:18:54.2929428</Date>
        <Author>$env:UserDomain\$env:UserName</Author>
        <Description>Automatically limit connected eGPU to safe wattage for power supply</Description>
        <URI>\NVIDIA Power Limit</URI>
    </RegistrationInfo>
    <Triggers>
        <LogonTrigger>
            <Enabled>true</Enabled>
        </LogonTrigger>
    </Triggers>
    <Principals>
        <Principal id="Author">
            <UserId>$env:UserSID</UserId>
            <LogonType>S4U</LogonType>
            <RunLevel>HighestAvailable</RunLevel>
        </Principal>
    </Principals>
    <Settings>
        <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
        <AllowHardTerminate>false</AllowHardTerminate>
        <StartWhenAvailable>true</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
        <IdleSettings>
            <StopOnIdleEnd>true</StopOnIdleEnd>
            <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
        <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
        <Priority>7</Priority>
    </Settings>
    <Actions Context="Author">
        <Exec>
            <Command>powershell</Command>
            <Arguments>-ExecutionPolicy RemoteSigned -File "$path\powerlimit.ps1"</Arguments>
        </Exec>
    </Actions>
</Task>
"@

    <# Delete existing task, if any #>
    schtasks /delete /tn "\NVIDIA Power Limit" /f 2>1

    <# Import scheduled task #>
    schtasks /create /xml "$path\powerlimit.xml" /tn "\NVIDIA Power Limit" /ru "$env:UserDomain\$env:UserName"
}


<# 
FINALIZATION
#>

if ($ok) {
    Write-Host "`n... Complete!" -ForegroundColor Green
    
    Write-Host "`nTo ensure the operation was successful, disconnect your GPU and reboot your PC, " -ForegroundColor Yellow
    Write-Host "then reconnect the GPU and run the command:" -ForegroundColor Yellow

    Write-Host "`nnvidia-smi.exe --query-gpu=power.limit --format=csv"

    Write-Host "`nIf your desired power limit is returned, you're good to go!`n"
}

<# Prompt for exit #>
Read-Host "Press ENTER to continue"