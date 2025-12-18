# AVD Direct Launch URI
# https://learn.microsoft.com/en-us/azure/virtual-desktop/uri-scheme?WT.mc_id=AZ-MVP-5004159


# Get the remote desktop application group ResourceID
$parameters = @{
     ResourceGroupName      = "<ResourceGroupName>"
     ApplicationGroupName   = "<ApplicationGroupName>"
}
Get-AzWvdDesktop @parameters | FT Name, ObjectId


# Build the URI with embedded ObjectId and User UPN
windows365.exe "ms-avd:connect?resourceid=<ObjectId>&username=<UserUPN>"


# without username (fails, username is required)
windows365.exe "ms-avd:connect?resourceid=<ObjectId>"


# Input box to ask for UPN
# Use multiple monitors set to true
Add-Type -AssemblyName Microsoft.VisualBasic
$UserName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your UPN", "User UPN Input", "")
windows365.exe "ms-avd:connect?&resourceid=<ObjectId>&username=$UserName&usemultimon=true"


# Get the Remote App ObjectId
$parameters = @{
    ResourceGroupName      = "<ResourceGroupName>"
    ApplicationGroupName   = "<RemoteApplicationGroupName>"
}
Get-AzWvdApplication @parameters | FT Name, ObjectId


# Get the UPN of the logged in user using the .NET Framework
$UserName = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current.UserPrincipalName
windows365.exe "ms-avd:connect?&resourceid=<ObjectId>&username=$UserName"
