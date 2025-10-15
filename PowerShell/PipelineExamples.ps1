# PowerShell Pipeline Examples

# 1 Get-Process
get-process

Get-process | Sort-Object CPU -Descending

Get-Process | Sort-Object CPU -Descending -top 10

Get-Process | Sort-Object name 


# Demo 2
get-service

get-service | Where-Object {$_.status -ne 'Stopped'}


# DEMO 3
Get-Process | Where-Object { $_.CPU -gt 5 }

Get-Process | Where-Object { $_.CPU -gt 5 } | Sort-Object CPU -Descending

# Deallocate shut down VMs in Azure
# Sign in to Azure with rights to manage VMs

Get-AzVM -ResourceGroupName AAPoShDemo -status

Get-AzVM -ResourceGroupName AAPoShDemo -status | Where-Object {$_.PowerState -eq "VM stopped"}

Get-AzVM -ResourceGroupName AAPoShDemo -status | Where-Object {$_.PowerState -eq "VM stopped"} | Stop-AzVM -force
