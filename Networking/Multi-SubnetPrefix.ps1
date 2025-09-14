#region
# Create a new resource group.
New-AzResourceGroup -Name 'SubnetDemoRG' -Location 'WestUS'
# Create a new VNet with a single Subnet prefix.
$subnet = @{
    Name                     = 'demosubnet'
    AddressPrefix            = '10.50.1.0/24'  
}
$subnetConfig = New-AzVirtualNetworkSubnetConfig @subnet

$virtualNetworkParams = @{
    ResourceGroupName        = 'SubnetDemoRG'
    Location                 = 'WestUS'
    Name                     = 'vnet-demo-subnet'
    AddressPrefix            = '10.50.0.0/16'
    Subnet                   = $subnetConfig
}
New-AzVirtualNetwork @virtualNetworkParams
#endregion


# Verify Azure subscription connection.
Connect-AzAccount
# Verify that the Az.Network module version 4.3.0 or newer is installed.
Get-InstalledModule -Name Az.Network
# If not installed, run the following command to install it.
Install-Module -Name Az.Network -AllowClobber



### Example 1: Add multiple prefixes to an existing Subnet.
# Get the existing virtual network
$vnet = Get-AzVirtualNetwork -ResourceGroupName 'SubnetDemoRG' -Name 'vnet-demo-subnet'
# View existing subnets
$vnet.Subnets
# Create a multi-prefix subnet
$subnet = @{
    virtualNetwork          = $vnet
    Name                     = 'demosubnet'
    AddressPrefix            = '10.50.1.0/24','10.50.2.0/24' # Important: Add existing and new address prefixes
}
set-AzVirtualNetworkSubnetConfig @subnet
# Update the virtual network with the new subnet
$vnet | Set-AzVirtualNetwork
# View the updated virtual network
(Get-AzVirtualNetwork -ResourceGroupName 'SubnetDemoRG' -Name 'vnet-demo-subnet').Subnets



### Example 2: Create a new virtual network with a multi-prefix subnet.
# Create a multi-prefix subnet
$subnet = @{
    Name                     = 'multisubnet'
    AddressPrefix            = '10.110.2.0/24', '10.210.2.0/24'  # Multiple prefixes
}
$subnetConfig = New-AzVirtualNetworkSubnetConfig @subnet
# Create a virtual network with the multi-prefix subnet
$virtualNetworkParams = @{
    ResourceGroupName        = 'SubnetDemoRG'
    Location                 = 'WestUS'
    Name                     = 'multi-vnet'
    AddressPrefix            = '10.110.0.0/16', '10.210.0.0/16'  # Multiple address spaces
    Subnet                   = $subnetConfig
}
New-AzVirtualNetwork @virtualNetworkParams
# View subnets in the virtual network
(Get-AzVirtualNetwork -ResourceGroupName 'SubnetDemoRG' -Name 'multi-vnet').Subnets



## Example 3: Remove a prefix from a multi-prefix subnet.
# Get the existing virtual network
$vnet = Get-AzVirtualNetwork -ResourceGroupName 'SubnetDemoRG' -Name 'vnet-demo-subnet'
# View existing subnets
$vnet.Subnets
# Set the subnet to modify
$subnet = @{
    virtualNetwork          = $vnet
    Name                     = 'demosubnet'
    AddressPrefix            = '10.50.1.0/24'  # Remove the second prefix'
}
set-AzVirtualNetworkSubnetConfig @subnet
# Update the virtual network with the modified subnet
$vnet | Set-AzVirtualNetwork
# View the updated virtual network
(Get-AzVirtualNetwork -ResourceGroupName 'SubnetDemoRG' -Name 'vnet-demo-subnet').Subnets



