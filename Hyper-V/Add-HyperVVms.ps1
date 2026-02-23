<#
.SYNOPSIS
Creates multiple Hyper-V Generation 2 virtual machines from a sysprepped image.

.DESCRIPTION
This script creates a specified number of Hyper-V virtual machines based on a sysprepped VHD image.
Each VM is assigned a sequential number and created as Generation 2 with TPM support and secure boot enabled.
VM names are limited to 13 alphanumeric characters.
The script supports configurable memory, processor count, and automatic VM startup.

.PARAMETER vmPrefix
The prefix for VM names (1-13 alphanumeric characters only). Sequential numbers will be appended.
Required parameter.

.PARAMETER vmCount
The number of virtual machines to create.
Required parameter.

.PARAMETER sourceImagePath
The full path to the sysprepped VHD template image.
Required parameter.

.PARAMETER destinationPath
The directory where VM virtual disks folders will be created.
Required parameter.

.PARAMETER memoryInGB
The startup memory allocation for each VM. Default is "4GB".
Optional parameter.

.PARAMETER processorCount
The number of virtual processors for each VM. Default is 2.
Optional parameter.

.PARAMETER startVM
Boolean to determine if VMs should be started after creation. Default is $true.
Optional parameter.

.NOTES
Author: Travis Roberts, Ciraltos llc
Date: February 21, 2026
VM names are limited to 13 characters and two numbers appended due to Windows computer name restrictions.
Requires Hyper-V administrative privileges.
Generation 2 VMs support TPM and secure boot for enhanced security.

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
.\Add-HyperVVMs.ps1 -vmPrefix "Test" -vmCount 3 -sourceImagePath "D:\images\template.vhdx" -destinationPath "D:\VMs"
Creates 3 VMs named Test01, Test02, Test03 with default settings.

.EXAMPLE
.\Add-HyperVVMs.ps1 -vmPrefix "Win11Lab" -vmCount 2 -sourceImagePath "D:\images\Win11.vhdx" -destinationPath "D:\VMs" -memoryInGB 8GB -processorCount 4 -startVM $false
Creates 2 VMs with 8GB memory and 4 processors without starting them.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateLength(1, 13)]
    [ValidatePattern('^[a-zA-Z0-9]+$')]
    [string] $vmPrefix,
    [Parameter(Mandatory)]
    [int] $vmCount,
    [Parameter(Mandatory)]
    [string] $sourceImagePath,
    [Parameter(Mandatory)]
    [string] $destinationPath,
    [Parameter()]
    [string] $memoryInGB = "4GB",
    [Parameter()]
    [int] $processorCount = 2,
    [Parameter()]
    [bool] $startVM = $true
)

# Verify that the source image exists and the destination path is valid
if (-not (Test-Path -Path $sourceImagePath)) {
    Write-Host "The source image path '$sourceImagePath' does not exist. Please provide a valid path." -ForegroundColor Red
    exit
}
if (-not (Test-Path -Path $destinationPath)) {
    Write-Host "The destination path '$destinationPath' does not exist. Please provide a valid path." -ForegroundColor Red
    exit
}

# Create an array of VM names based on the prefix and count
$vmNames = @()
$count = 1
while ($count -le $vmCount) {
    $vmSuffix = $count.ToString("D2") # Format the number with leading zeros (e.g., 01, 02, 03)
    $vmNames += "$vmPrefix$($vmSuffix)"
    $count++
}

# Test against current VMs for duplicate VM names
$ExistingVMs = (get-vm).name
$matches = Compare-object -ReferenceObject $ExistingVMs -DifferenceObject $vmNames -IncludeEqual -ExcludeDifferent 
If ($matches) {
    Write-Host "The following VM names already exist: $($matches.InputObject -join ', '). Please choose a different prefix." -ForegroundColor Red
    #exit
}

foreach ($vmName in $vmNames) {
    # Create the destination path for the VM's VHDX
    $vmPath = Join-Path -Path $destinationPath -ChildPath $vmName
    if (-not (Test-Path -Path $vmPath)) {
        New-Item -Path $vmPath -ItemType Directory -ErrorAction Stop | Out-Null
    }

    # Copy the base VHDX to the new location
    $vhdxPath = Join-Path -Path $vmPath -ChildPath ("$vmName.vhdx")
    Write-Host "Copying VHDX to '$vhdxPath'..." -ForegroundColor Green
    Copy-Item -Path $sourceImagePath -Destination $vhdxPath -ErrorAction Stop

    # Create the new VM
    Write-Host "Creating VM '$vmName'..." -ForegroundColor Green
    New-VM -Name $vmName -MemoryStartupBytes ([int64]$memoryInGB) -Generation 2 -Path $destinationPath

    # Add the VHDX to the VM
    Add-VMHardDiskDrive -VMName $vmName -Path $vhdxPath

    # Set the VM core count
    Set-VMProcessor -VMName $vmName -Count $processorCount

    # Enable TPM for the VM
    Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector
    Enable-VMTPM -VMName $vmName

    # Output status
    Write-Host "VM '$vmName' has been created successfully." -ForegroundColor Green

    # Start the VM if specified
    if ($startVM) {
        Start-VM -Name $vmName
        Write-Host "VM '$vmName' has been created and started successfully." -ForegroundColor Green
    } else {
        Write-Host "VM '$vmName' has been created successfully. You can start it using Start-VM -Name '$vmName'." -ForegroundColor Green
    }
}
