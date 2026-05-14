# DISCLAIMER:
# This code is provided "AS IS" without warranties of any kind, express or implied,
# including but not limited to merchantability, fitness for a particular purpose, and
# non-infringement. Use at your own risk; validate in a test environment before production use.

# Source: https://learn.microsoft.com/en-us/azure/virtual-desktop/deploy-azure-virtual-desktop-hybrid

# Requires the az.desktopvirtualization module
# Install-Module -Name az.desktopvirtualization

# 1. Get the host pool registration token. This token is valid for 24 hours with the default settings. You can customize the token's expiration time and other settings as needed.
# Fill in the parameters for your environment
$HostPoolName = "<HostPoolName>" # The name of the host pool
$HostPoolRG = "<HostPoolRG>" # The resource group of the host pool
$machineName = "<machineName>" # The name of the arc-enabled computer you want to register (must be unique within the host pool)
$machineRegion = "<machineRegion>" # The Azure region where the session host ARC resource is located (may be different from the host pool's region)

# Create the registration token with a custom expiration time (optional)
$expiresUtc = (Get-Date).ToUniversalTime().AddHours(24).ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
$regInfo    = New-AzWvdRegistrationInfo -ResourceGroupName $HostPoolRG -HostPoolName $HostPoolName -ExpirationTime $expiresUtc
$token      = $regInfo.Token

# 2. Install the Cloud Device Extension on the session host using the registration token. This extension will use the token to register the session host with the host pool.
# Settings
$settings= @{ isCloudDevice = $false }
$protectedSettings = @{ registrationToken = $token }

# Install extension on the session host (Using Splatting for parameters that require the session host's details)
$extensionParams = @{
	Name             = 'Microsoft.AzureVirtualDesktop.CloudDeviceExtension'
	ResourceGroupName = $HostPoolRG
	MachineName      = $machineName
	Location         = $machineRegion
	Publisher        = 'Microsoft.AzureVirtualDesktop'
	ExtensionType    = 'CloudDeviceExtension'
	Setting          = $settings
	ProtectedSetting = $protectedSettings
}
New-AzConnectedMachineExtension @extensionParams
