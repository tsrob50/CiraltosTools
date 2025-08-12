<#
.SYNOPSIS
    A Custom Script Extensions that updates settings on an Azure Virtual Machines.
    This script is used to demonstrate the use of Azure Custom Script Extensions (CSE) to automate VM configuration tasks.

.DESCRIPTION
    This script automates the configuration of Azure VM's with Azure Custom Script Extensions (CSE).
    It sets the timezone, registered owner and organization, installs BGInfo for system information display,
    and installs Google Chrome using Chocolatey. The script logs all actions to a specified log file
    and handles errors with a try-catch block.

.PARAMETER LogDir
This parameter is used to set the directory for log files. It is expected to be a string. The default value is "c:\CSELog" and it is optional.

.PARAMETER DownloadDir
This parameter is used to set the directory for downloading files. It is expected to be a string. The default value is "c:\CSEDownloads" and it is optional.

.PARAMETER timeZone
This parameter is used to set the desired timezone for the VM. It is expected to be a string representing the timezone name, and it is mandatory.
Use "tzutil /l" from Windows to view available time zones by name.

.PARAMETER owner
This parameter is used to set the registered owner name for the VM. It is expected to be a string, and it is mandatory.

.PARAMETER organization
This parameter is used to set the registered organization name for the VM. It is expected to be a string, and it is mandatory.

.PARAMETER bgInfoConfigUrl
Specifies the bgInfoConfigUrl parameter. This parameter is used to set the URL for the BGInfo configuration file. It is expected to be a string, and it is optional.

.EXAMPLE
.\VM-CSEParam.ps1 -logDir "c:\CSELog" -downloadDir "c:\CSEDownloads" -timeZone "Pacific Standard Time" -owner "John Doe" -organization "Contoso Ltd"

.NOTES
    Author: Travis Roberts
    Date: August 12, 2025
    Version: 1.1
        Convert variables to parameters.

    Copyright (c) 2025 Travis Roberts

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$logDir = "c:\CSELog",

    [Parameter(Mandatory=$false)]
    [string]$downloadDir = "c:\CSEDownloads",

    [Parameter(Mandatory=$true)]
    [string]$timeZone,

    [Parameter(Mandatory=$true)]
    [string]$owner,

    [Parameter(Mandatory=$true)]
    [string]$organization,

    [Parameter(Mandatory=$false)]
    [string]$bgInfoConfigUrl = "https://github.com/tsrob50/CiraltosTools/raw/refs/heads/main/VM/bginfo.bgi"
)

#region LogFile
# Check if the log directory exists, if not create it
Try{
    if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir
}
}
catch {
    Write-Error "Failed to create log directory: $_.Exception.Message"
}
# Create the log file with the current date
$logFile = Join-Path $logDir "$(get-date -format 'yyyyMMdd')_softwareinstall.log"
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
#endregion


#region Create the download directory
# Check if the download directory exists, if not create it
try {
    if (-not (Test-Path $downloadDir)) {
        New-Item -ErrorAction Stop -ItemType Directory -Path $downloadDir
        Write-Log "Download directory created at $downloadDir"
    }
    else {
        Write-Log "Download directory already exists at $downloadDir"
    }
}
catch {
    Write-Log "Failed to create or verify download directory: $_.Exception.Message"
}

#region set the servers timezone
try {
    set-timezone -ErrorAction Stop -id $timeZone
    Write-Log "Timezone set to $timeZone successfully."
}
catch {
    Write-Log "Failed to set timezone: $_.Exception.Message"
}
#endregion


#region set the registered owner and organization
# Run "winver" to verify the changes
try {
    # Ensure the registry key "RegisteredOwner" exists
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOwner")) {
        New-Item -ErrorAction Stop -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOwner" -Force | Out-Null
    }
    set-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOwner" -Value $owner -Force

    # Ensure the registry key "RegisteredOrganization" exists
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOrganization")) {
        New-Item -ErrorAction Stop -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\RegisteredOrganization" -Force | Out-Null
    }
    set-itemproperty -ErrorAction Stop -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "RegisteredOrganization" -Value $organization -Force
    Write-Log "Registered owner and organization set to '$owner' and '$organization' successfully. Use the 'WinVer' command to verify."
}
catch {
    Write-Log "Failed to set registered owner and organization: $_.Exception.Message"
}
#endregion


#region add BGInfo to the system
# Check if BGInfo is already installed
if (Test-Path "c:\$downloadDir\BGInfo\BGInfo.exe") {
    Write-Log "BGInfo is already installed."
}
else {
    try {
        invoke-webrequest -ErrorAction Stop -Uri "https://download.sysinternals.com/files/BGInfo.zip" -UseBasicParsing -OutFile "$downloadDir\BGInfo.zip"
        Expand-Archive -ErrorAction Stop -Path "$downloadDir\BGInfo.zip" -DestinationPath "$downloadDir\BGInfo" -Force
        Remove-Item -ErrorAction Stop -Path "$downloadDir\BGInfo.zip"
    }
    catch {
        Write-Log "Failed to download or extract BGInfo: $_.Exception.Message"
    }
}
# Download the BGInfo configuration file
try {
    $bgInfoConfigPath = "$downloadDir\BGInfo\bginfo.bgi"
    Invoke-WebRequest -ErrorAction Stop -Uri $bgInfoConfigUrl -UseBasicParsing -OutFile $bgInfoConfigPath
    Write-Log "BGInfo configuration file downloaded successfully."
}
catch {
    Write-Log "Failed to download BGInfo configuration file: $_.Exception.Message"
}
# Set up BGInfo to run at startup
$bgInfoPath = "$downloadDir\BGInfo\BGInfo.exe"
if (Test-Path $bgInfoPath) {
    $bgInfoStartupPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\BGInfo.lnk"
    $bgInfoShortcut = New-Object -ErrorAction Stop -ComObject WScript.Shell
    $shortcut = $bgInfoShortcut.CreateShortcut($bgInfoStartupPath)
    $shortcut.TargetPath = $bgInfoPath
    $shortcut.Arguments = "$downloadDir\BGInfo\bginfo.bgi /nolicprompt /timer:0 /silent"
    $shortcut.Save()
    Write-Log "BGInfo shortcut created successfully."
}
else {
    Write-Log "BGInfo executable not found at $bgInfoPath. Shortcut not created."
}
#endregion


#region install Chrome with Chocolatey
# Check if Chocolatey is already installed and install if not with logging
try {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    else {
        Write-Log "Chocolatey is already installed"
    }
}
catch {
    Write-Log "Error installing Chocolatey: $($_.Exception.Message)"
}
# Install Chrome with Chocolatey with logging
try {
    if (Test-Path -ErrorAction Stop "C:\Program Files\Google\Chrome\Application\chrome.exe") {
        Write-Log "Google Chrome is already installed."
        return
    }
    else {
        Write-Log "Google Chrome is not installed, proceeding with installation."
        Write-Log "Installing Google Chrome with Chocolatey"
        $chromeInstall = choco install googlechrome --yes --ignore-checksums --no-progress --log-level=error
        Write-Log "Chrome install output: $chromeInstall" -Wait
    }
    # Verify installation
    if (Test-Path -ErrorAction Stop "C:\Program Files\Google\Chrome\Application\chrome.exe") {
        Write-Log "Google Chrome has been installed successfully"
    }
    else {
        Write-Log "Error verifying the installation of Google Chrome"
    }
}
catch {
    Write-Log "Error installing Google Chrome: $($_.Exception.Message)"
}
#endregion
