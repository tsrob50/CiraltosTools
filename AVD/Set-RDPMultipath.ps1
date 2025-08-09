<#
.SYNOPSIS
This script sets the RDP Multipath feature in the Windows registry. Run it on AVD session hosts to enable or disable the RDP Multipath feature.

.DESCRIPTION
RDP Multipath allows multiple network paths to be used for Remote Desktop Protocol (RDP) connections, enhancing reliability and performance.
RDP Multipath should be enabled by default on host pools without requiring any additional configuration.
Use this script to enable as the feature is being rolled out or disable the feature for troubleshooting.
This script checks if the necessary registry key exists, creates it if it does not, and sets the value based on the input parameter.
The script can be used as a Custom Script Extension to enable RDP Multipath, or it can be run manually on session hosts.

.PARAMETER rdpMultipath
Specifies whether to enable or disable the RDP Multipath feature. Accepts "Enabled" to set the registry value to 100, or "Disabled" to set it to 0.

.EXAMPLE
./Set-RDPMultipath.ps1 -rdpMultipath "Enabled"

.NOTES
    Author: Travis Roberts
    Date: August 6, 2025
    Version: 1.0

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
    [Parameter()][ValidateSet("Enabled", "Disabled", IgnoreCase = $true)]
    [string]
    $rdpMultipath = "Enabled"
)

#Check if the registry key exists and if not, create it.
try {
    if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings")) {
        New-Item -ErrorAction Stop -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings" -Force
        write-output "Created registry key: HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings"
    }
}
catch {
    Write-Error "Failed to create or access the registry key: $($_.Exception.Message)"
    return
}   
# set the registry key value for RDP Multipath
# Valid values are "Enabled" (100) or "Disabled" (0)
try {
    # Set the registry key value based on the input parameter
    if ($rdpMultipath -eq "Enabled") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings" -Name "SmilesV3ActivationThreshold" -Value 100 -Type DWord
        Write-Output "RDP Multipath has been enabled."
    }
    elseif ($rdpMultipath -eq "Disabled") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RdpCloudStackSettings" -Name "SmilesV3ActivationThreshold" -Value 0 -Type DWord
        Write-Output "RDP Multipath has been disabled."
    }
}
catch {
    Write-Error "Failed to set registry key value $rdpMultipath : $($_.Exception.Message)"
}
