# Arrays in PowerShell

# 1 Create an array
$array1 = 'one', 'two', 'three'  # Comma is the array operator
$array1                          # Display the array
$array1.Count                    # Count the items in the array


# 2 View the array
$array1                          # View all items in the array
$array1[0]                       # View the first item in the array, use bracket notation, index starts at 0
$array1[1, 2]                    # View the second and third items in the array
$array1[0..2]                    # View the first through third items in the array, use range operator


# 3 Add to an array using +=
$array1 += 'for'                 # Add an item to the array
$array1                          # Display the array
$array1[3] = 'four'              # Update the fourth item in the array
$array1                          # Display the array
$array1 = $array1 -ne 'four'     # Remove an item from the array by value (replace the array with all items not equal to 'four')
$array1                          # Display the array


# 4 View the array item type
$array2 = 'one', 2, 'three'     # Create an array with mixed types
$array2[0] | Get-Member         # View the members (properties and methods) of the first item in the array
$array2[1] | Get-Member         # View the members (properties and methods) of the second item in the array


# 5 Create an array of objects
$folders = (Get-ChildItem -path /Users/travisroberts/Documents/Array)   # Get the folders in the specified path
$folders[0] | Format-List                                               # View the first item in the array, format as a list
$folders | Format-Table Name, CreationTime                              # Format the output as a table
$folders[1] | Get-Member                                                # View the members (properties and methods) of the object


# 6 Array subexpression operator
Get-Member -InputObject $array1         # View the members (properties and methods) of the array
$array3 = 1                             # Create a new array with a single item
Get-Member -InputObject $array3         # View the members (properties and methods) of the array
$array3 += 2                            # Add an item to the array
$array3                                 # Single item is retuned (1+2=3) not an array
$array3 = @(1)                          # Create a single value array
$array3 += 2                            # Add an item to the array
$array3                                 # View the array
Get-Member -InputObject $array3         # View the members (properties and methods) of the array


# 7 Use array in a loop
$folders = @(                       # Create an array of folder names (comma is optional with multiple lines)
    'DemoFolder1'
    'DemoFolder2'
    'DemoFolder3'
)

$folders                            # View the array

foreach ($folder in $folders) {
    # Loop through each item in the array
    New-Item -Path /Users/travisroberts/Documents/Array -Name $folder -ItemType Directory  # Create a folder for each item in the array
    write-host "Created folder: $folder"  # Display a message
}

Get-ChildItem -Path /Users/travisroberts/Documents/Array  # View the folders created


# 8 Looping to create Azure VMs

$vmNames = @('DemoVM1', 'DemoVM2', 'DemoVM3')       # Create an array of VM names

$credentials = Get-Credential                       # Set the credentials

foreach ($vmName in $vmNames) {                     # Loop through each VM name
    $vmParams = @{
        ResourceGroupName   = '<ResourceGroupName>'
        Name                = $vmName               # Use the VM name from the array
        Location            = '<Location>'
        VirtualNetworkName  = '<VirtualNetworkName>'
        SubnetName          = '<SubnetName>'
        SecurityGroupName   = "$vmName-NSG"         # Use the VM name to create a unique NSG name
        PublicIpAddressName = "$vmName-PublicIP"    # Use the VM name to create a unique Public IP name
        OpenPorts           = 3389
        Image               = 'MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest'
        Size                = '<Size>'
        Credential          = $credentials
        Zone                = '1'
    }
    New-AzVM @vmParams                              # Create a VM using splatting
}

foreach ($vmName in $vmNames) {
    # Loop through each VM name
    $newVmParams = @{
        ResourceGroupName = '<ResourceGroupName>'
        Name              = $vmName                 # Use the VM name from the array
    }
    Get-AzVM @newVmParams | Format-Table name,location, size   # Get the VM using splatting
}
