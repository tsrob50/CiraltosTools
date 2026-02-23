<#
.SYNOPSIS
Updates the computer name on a Hyper-V VM to match the VM name.

.DESCRIPTION
This script runs on a Hyper-V VM client to update the computer name to match the VM name.
The Hyper-V name must be less than 15 characters to be compatible with Windows computer name requirements.
This script reads the Hyper-V VM name from the registry and renames the computer accordingly.
A restart is required for the change to take effect.
Error handling is included to log any issues encountered during execution.
The script is called from a SetupComplete.cmd file located in C:\Windows\Setup\Scripts on the VM image.
Update the log file path and name at the $logFile variable as needed for your environment.


.NOTES
Author: Travis Roberts, Ciraltos llc
Date: February 21, 2026
Recommended execution: SetupComplete.cmd in C:\Windows\Setup\Scripts

Copyright (c) 2026 Travis Roberts

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


.EXAMPLE
powershell.exe -ExecutionPolicy Bypass -File C:\Update-Client.ps1
#>

# Variables for the script
$logDir = "C:\Windows\Setup\Scripts\Logs" # Directory to store logs

# Check if the log directory exists, if not create it
try {
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir
    }
}
catch {
    Write-Error "Failed to create log directory: $_.Exception.Message"
}
# Create the log file with the current date
$logFile = Join-Path $logDir "$(Get-Date -Format 'yyyyMMdd')_SetupScripts.log"

function Write-Log {
    Param($message)
    Write-Output "$(Get-Date -Format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}

# Get the Hyper-V VM name from the registry
try {
    $vmName = (Get-ItemProperty -ErrorAction Stop -Path "HKLM:SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters").VirtualMachineName
    Write-Log "Retrieved VM name from registry: $vmName"
}
catch {
    Write-Log "Failed to retrieve VM name from registry: $_.Exception.Message"
    exit
}

# Change the computer name to match the VM name
try {
    if ($env:COMPUTERNAME -ne $vmName) {
        Rename-Computer -NewName $vmName -Force -ErrorAction Stop
        # (gwmi win32_computersystem).Rename($vmName); shutdown -r -t 0
        Write-Log "Computer name changed to '$vmName'. A restart is required for the change to take effect."
        shutdown -r -t 0
    }
}
catch {
    Write-Log "Failed to rename computer: $_.Exception.Message"
}
