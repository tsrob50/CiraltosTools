<#
.SYNOPSIS
Creates a basic Azure VPN Gateway for a specified Virtual Network.

.DESCRIPTION
This script provisions a basic VPN Gateway in Azure for an existing Virtual Network. 
It automates the process of creating the necessary gateway subnet, public IP address, 
and the VPN Gateway resource itself. The script is intended to simplify the deployment 
of a basic VPN Gateway for secure cross-premises connectivity.

############################################################
## Not all subscriptions support the standard IP SKU 
## If deployment fails with 'One or more operations failed'
## remove Gateway, Public IP, and GatewaySubnet and
## run again with -standardIP $false
############################################################

.PARAMETER rgName
Specifies the name of existing virtual networks Azure Resource Group.
This is where the VPN Gateway will be created.

.PARAMETER vnetName
Specifies the name of the existing Virtual Network to which the VPN Gateway will be attached.

.PARAMETER gwName
Provide a name for the new VPN Gateway to be created.

.PARAMETER addressPrefix
Specifies the address prefix (in CIDR notation) for the Gateway Subnet (e.g., "10.0.1.0/24").
This address space must be in the virtual networks address space and not overlap with any existing subnets.
The smallest address space that can be used is /29. Recommended is /27 or larger for future scalability.

.PARAMETER standardIP
(optional) Indicates whether to use a Standard Public IP address (if $true) or a Basic Public IP address (if $false). Default is $true.
Basic Public IP addresses will be retired at the end of September 2025.
Only use Basic Public IP addresses if standard is not available in the region.

.EXAMPLE
.\New-azBasicVPNGateway.ps1 -rgName "MyResourceGroup" -vnetName "MyVNet" -gwName "MyVPNGateway" -addressPrefix "10.0.1.0/24"
Creates a basic VPN Gateway named "MyVPNGateway" in the "MyResourceGroup" resource group, attached to "MyVNet" in the virtual network region, using the specified address prefix and a Standard Public IP.

.NOTES
Author: Travis Roberts
Date: 2025-06-13
Version: 1.0 First release.
Date: 2025-07-06
Version: 1.1 Add steps to remove the Gateway, Public IP, and GatewaySubnet if the deployment fails.

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
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$rgName,

    [Parameter(Mandatory = $true)]
    [string]$vnetName,

    [Parameter(Mandatory = $true)]
    [string]$gwName,

    [Parameter(Mandatory = $true)]
    [string]$addressPrefix,

    [Parameter(Mandatory = $false)]
    [ValidateSet($true, $false)]
    [bool]$standardIP = $true
)

<# Variables for interactive testing
$rgName = "<resource group name>"
$vnetName = "<virtual network name>"
$subnetName = "GatewaySubnet" #Don't change this name, it is a reserved name for the gateway subnet
$gwName = "<Gateway name>"
$addressPrefix = "<ip address prefix for the gateway subnet"
#>

# Ensure the required Az PowerShell modules are installed and the user is logged in to Azure.
# This section checks for the necessary modules and prompts the user to log in if not already authenticated
try {
    # List of required Az modules for this script
    $requiredModules = @(
        "Az.Accounts",
        "Az.Network",
        "Az.Resources"
    )
    write-host "Checking for the required modules"
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -ErrorAction Stop -Name $module)) {
            throw "Required Az PowerShell module '$module' is not installed. Please install it before running this script."
        }
    }

    # Check if user is logged in
    write-host "Verifying the session is logged into Azure"
    if (-not (Get-AzContext -ErrorAction Stop)) {
        throw "You are not logged in to Azure. Please run 'Connect-AzAccount' first."
    }
}
catch {
    Write-Host "Initialization error: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Set the variable for the Gateway Subnet and location for the resources.
try {
    # Set the variable for the Gateway Subnet
    # The Gateway Subnet must be named "GatewaySubnet" and have a /27 or larger address space.
    $subnetName = "GatewaySubnet" 

    # Set the location for the resources
    $location = (Get-AzVirtualNetwork -ErrorAction Stop -ResourceGroupName $rgName -Name $vnetName).Location
}
catch {
    Write-Host "Failed to get virtual network or location: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Create the Gateway Subnet
# The gateway subnet must be named "GatewaySubnet" and have a /27 or larger address space.
# The address space must not overlap with the VNet address space.
Write-Host "Creating Gateway Subnet '$subnetName' with address prefix '$addressPrefix' in Virtual Network '$vnetName'"
# Check if the Gateway Subnet already exists
try {
    $vnet = Get-AzVirtualNetwork -ErrorAction Stop -ResourceGroupName $rgName -Name $vnetName
    if ($vnet.Subnets.Name -contains $subnetName) {
        Write-Host "Gateway Subnet '$subnetName' already exists in Virtual Network '$vnetName'. Script will exit." -ForegroundColor Yellow
        return
    }
    Add-AzVirtualNetworkSubnetConfig -ErrorAction Stop -Name $subnetName -AddressPrefix $addressPrefix -VirtualNetwork $vnet -WarningAction SilentlyContinue | Out-Null
    $vnet | Set-AzVirtualNetwork | Out-Null
}
catch {
    Write-Host "Failed to create Gateway Subnet: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Create the Standard or Basic Public IP address.
# Allocation Method must be Dynamic for Basic SKU or Static for Standard SKU.
# Standard Public IP addresses are used by default.
# Basic Public IP addresses will be used if -standardIP is set to $false.
# Basic Public IP addresses will be retired at the end of September 2025.
try {
    # Create the Public IP address
    if ($standardIP) {
        write-host "Creating Standard Public IP address for VPN Gateway '$gwName' in Resource Group '$rgName'"
        $gwpip = New-AzPublicIpAddress -ErrorAction Stop -Name ($gwName + "IP") -ResourceGroupName $rgName -Location $location -AllocationMethod Static -Sku Standard -Zone 1, 2, 3 -WarningAction SilentlyContinue
    }
    else {
        write-host "Creating Basic Public IP address for VPN Gateway '$gwName' in Resource Group '$rgName'"
        $gwpip = New-AzPublicIpAddress -ErrorAction Stop -Name ($gwName + "IP") -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic -Sku Basic
    }
}
catch {
    Write-Host "Failed to create Public IP address: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Attempting to remove the Public IP address and Gateway Subnet..." -ForegroundColor Yellow
    try {
        # Remove the Public IP address if it was created
        $pipName = $gwName + "IP"
        if (Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $pipName -ErrorAction SilentlyContinue) {
            Remove-AzPublicIpAddress -ResourceGroupName $rgName -Name $pipName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed Public IP address '$pipName'." -ForegroundColor Yellow
        }
        else {
            Write-Host "Public IP address '$pipName' does not exist. No removal needed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove Public IP address: $($_.Exception.Message)" -ForegroundColor Red
    }
    try {
        # Remove the GatewaySubnet if it was created
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -ErrorAction SilentlyContinue
        if ($vnet -and $vnet.Subnets.Name -contains $subnetName) {
            Remove-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue
            $vnet | Set-AzVirtualNetwork | Out-Null
            Write-Host "Removed Gateway Subnet '$subnetName'." -ForegroundColor Yellow
        }
        else {
            Write-Host "Gateway Subnet '$subnetName' does not exist. No removal needed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove Gateway Subnet: $($_.Exception.Message)" -ForegroundColor Red
    }
    return
}

# Create the gateway IP Address Configuration
try {
    Write-Host "Creating Gateway IP Configuration for VPN Gateway '$gwName' in Resource Group '$rgName'"
    $vnet = Get-AzVirtualNetwork -ErrorAction Stop -ResourceGroupName $rgName -Name $vnetName 
    $subnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop -Name $subnetName -VirtualNetwork $vnet
    $gwipconfig = New-AzVirtualNetworkGatewayIpConfig -ErrorAction Stop -Name gwipconfig -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id
}
catch {
    Write-Host "Failed to create gateway IP configuration: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Create the Basic VPN Gateway
try {
    Write-Host "Creating Basic VPN Gateway '$gwName' in Resource Group '$rgName' with IP Configuration"
    New-AzVirtualNetworkGateway -ErrorAction Stop -Name $gwName -ResourceGroupName $rgName -Location $location -IpConfigurations $gwipconfig -VpnType "RouteBased" -GatewaySku Basic | Out-Null
}
catch {
    Write-Host "Failed to create VPN Gateway: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Try running the script again with "-standardIP $false" to use a Basic Public IP address.' -ForegroundColor Yellow
    Write-Host "Also, verify your account has permissions to create a VPN Gateway in the specified Resource Group and is not a guest account." -ForegroundColor Yellow
    Write-Host "Attempting to remove the VPN Gateway, Public IP address, and Gateway Subnet..." -ForegroundColor Yellow
    try {
        # Remove the VPN Gateway if it was created
        if (Get-AzVirtualNetworkGateway -ResourceGroupName $rgName -Name $gwName -ErrorAction SilentlyContinue) {
            Remove-AzVirtualNetworkGateway -ResourceGroupName $rgName -Name $gwName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed VPN Gateway '$gwName'." -ForegroundColor Yellow
        }
        else {
            Write-Host "VPN Gateway '$gwName' does not exist. No removal needed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove VPN Gateway: $($_.Exception.Message)" -ForegroundColor Red
    }
    try {
        # Remove the Public IP address if it was created
        $pipName = $gwName + "IP"
        if (Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $pipName -ErrorAction SilentlyContinue) {
            Remove-AzPublicIpAddress -ResourceGroupName $rgName -Name $pipName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed Public IP address '$pipName'." -ForegroundColor Yellow
        }
        else {
            Write-Host "Public IP address '$pipName' does not exist. No removal needed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove Public IP address: $($_.Exception.Message)" -ForegroundColor Red
    }
    try {
        # Remove the GatewaySubnet if it was created
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $vnetName -ErrorAction SilentlyContinue
        $subnetName = "GatewaySubnet"
        if ($vnet -and $vnet.Subnets.Name -contains $subnetName) {
            Remove-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -ErrorAction SilentlyContinue
            $vnet | Set-AzVirtualNetwork | Out-Null
            Write-Host "Removed Gateway Subnet '$subnetName'." -ForegroundColor Yellow
        }
        else {
            Write-Host "Gateway Subnet '$subnetName' does not exist. No removal needed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to remove Gateway Subnet: $($_.Exception.Message)" -ForegroundColor Red
    }
    return
}
