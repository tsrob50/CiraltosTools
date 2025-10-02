# Splatting in PowerShell


$car = @{
    Make  = 'Toyota'
    Model = 'Camry'
    Year  = 2025
    Color = 'Blue'
}

$car.Color
$car | Format-Table
$car | Get-Member
$car.add('price', 30000)


# Set the credentials
$credentials = Get-Credential

# Create a VM - One Line
new-azvm -ResourceGroupName 'AASplatting' -Name 'DemoVM1' -Location 'CentralUS' -VirtualNetworkName 'VNet03' -SubnetName 'Default' -SecurityGroupName 'DemoVM1NSG' -PublicIpAddressName 'myPublicIP' -OpenPorts 3389 -Image 'MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest' -Size 'Standard_B2ms' -Credential $credentials


# Create a VM - Splatting
$vmParams = @{
    ResourceGroupName     = 'AASplatting'
    Name                  = 'DemoVM2'
    Location              = 'CentralUS'
    VirtualNetworkName    = 'VNet03'
    SubnetName            = 'Default'
    SecurityGroupName     = 'DemoVM2NSG'
    PublicIpAddressName   = 'myPublicIP2'
    OpenPorts             = 3389
    Image                 = 'MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest'
    Size                  = 'Standard_B2ms'
    Credential            = $credentials
    Zone                  = '1'
}

New-AzVM @vmParams


# Get the VM
$newVmParams = @{
    ResourceGroupName = 'AASplatting'
    Name              = 'DemoVM2'
}
Get-AzVM @newVmParams
