
# Run against one Azure VM with a public script.
Set-AzVMCustomScriptExtension -ResourceGroupName AACustomScriptExtension -VMName CSEDemo1 -Location CentralUS `
    -FileUri "https://raw.githubusercontent.com/tsrob50/CiraltosTools/refs/heads/main/VM/CSEwParamsExample.ps1" -Run 'CSEwParamsExample.ps1' -Name DemoScriptExtension `
    -Argument "-timeZone `"<TimeZone>`" -owner `"<Owner>`" -organization `"<Organization>`"" # Use backtick marks for escaping


# Run against one Azure VM with a private Azure Storage script.
# Use backtick marks for escaping in the "Argument" text string.
-VMName "<VMName>" `
    -Location "<Location>" `
    -Name "<ExtensionName>" `
    -StorageAccountName "<StorageAccountName>" `
    -StorageAccountKey "<StorageAccountKey>" `
    -ContainerName "<ContainerName>" `
    -Filename "<ScriptFileName>" `
    -Run '<ScriptFileName>' `
    -Argument "-logDir `"<LogDir>`" -downloadDir `"<DownloadDir>`" -timeZone `"<TimeZone>`" -owner `"<Owner>`" -organization `"<Organization>`"" `
    -NoWait

# View the custom script extension status
Get-AzVMCustomScriptExtension -ResourceGroupName "<ResourceGroupName>" -VMName "<VMName>" -Name "<ExtensionName>" | Format-List



# Run custom script extensions against multiple VMs.
# set the resource group of the VM's.
$resourceGroupName = "<ResourceGroupName>"

# Get the list of VM names in the resource group.
$vms = (Get-AzVM -ResourceGroupName $resourceGroupName).Name
# -OR-
# Create a list of VMs manually.
$vms = @("<VMName1>", "<VMName2>")

# Create a hashtable for the script extension parameters and run the set-azVmCustomScriptExtension command on each VM.
foreach ($vm in $vms) {
    $scriptExtensionParams = @{
        ResourceGroupName  = $resourceGroupName
        VMName             = $vm
        Location           = '<Region>'
        Name               = '<ExtensionName>'
        StorageAccountName = '<StorageAccountName>'
        StorageAccountKey  = '<StorageAccountKey>'
        ContainerName      = '<ContainerName>'
        Filename           = '<ScriptFileName>'
        Run                = '<ScriptFileName>'
        Argument           = '-logDir "<LogDir>" -downloadDir "<DownloadDir>" -timeZone "<TimeZone>" -owner "<Owner>" -organization "<Organization>"'
        NoWait             = $true
    }
    Set-AzVMCustomScriptExtension @scriptExtensionParams
}

# View the custom script extension status.
Get-AzVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName "<VMName>" -Name "<ExtensionName>" | Format-List

# Remove the custom script extension.
foreach ($vm in $vms) {
    Remove-AzVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName $vm -Name "<ExtensionName>" -Force -NoWait
}
