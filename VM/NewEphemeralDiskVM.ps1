# Login to Azure account
Connect-AzAccount
Get-AzSubscription
Select-AzSubscription -SubscriptionName '<SubscriptionName>'

# Set the credentials
$credentials = Get-Credential

# Create a VM
$rgName        = '<ResourceGroupName>'
$vmName        = '<VMName>'
$location      = '<Location>'
$vnetRgName    = '<VNetResourceGroupName>'
$vnetName      = '<VNetName>'
$subnetName    = '<SubnetName>'
$vmSize        = '<VMSize>'


# Set the virtual network and subnet
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRgName 
$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }


# Create the network interface
$nic = New-AzNetworkInterface -Name "$vmName-NIC" -ResourceGroupName $rgName -Location $location -Subnet $subnet `
-PublicIpAddress $publicIpAddress -NetworkSecurityGroup $nsg


# Build the VM configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

$vmConfig = set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credentials -ProvisionVMAgent -EnableAutoUpdate

$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
-Skus '2022-datacenter-azure-edition' -Version 'latest'    

$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Set the VM to use an ephemeral OS disk
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -DiffDiskSetting Local -Caching ReadOnly -DiffDiskPlacement NvmeDisk -CreateOption FromImage
# DiffDiskSetting Local specifies an ephemeral OS disk
# DiffDiskPlacement NvmeDisk places the ephemeral OS disk on NVMe storage if available
# DiffDiskPlacement options: ResourceDisk, NvmeDisk

# Create the VM
New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig


# Get the VM
$newVmParams = @{
    ResourceGroupName = $rgName
    Name              = $vmName
}
(Get-AzVM @newVmParams).StorageProfile.OsDisk.DiffDiskSettings
