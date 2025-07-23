# Create a self-signed certificate for signing MSIX packages
$certParams = @{
    Type              = 'Custom'
    KeyUsage          = 'DigitalSignature'
    CertStoreLocation = 'Cert:\CurrentUser\My'
    TextExtension     = @(
        '2.5.29.37={text}1.3.6.1.5.5.7.3.3'
        '2.5.29.19={text}'
    )
    Subject           = 'CN=<CommonName>, O=<Orgainzation>, C=<CountryName>'
    FriendlyName      = 'Code Signing Cert'
}
$cert = New-SelfSignedCertificate @certParams

# View the certificate
Set-Location Cert:\CurrentUser\My
Get-ChildItem | Format-Table Subject, FriendlyName, Thumbprint

# Export the package signing certificate to a file with a password
$certPath = 'C:\Users\<UserName>\Documents\MSIXCodeCert.pfx'
$certPassword = ConvertTo-SecureString -String '<Password>' -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPassword

# Import the certificate into the TrustedPeople store
Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\CurrentUser\TrustedPeople' -Password $certPassword 

# Export the public key to a .cer file
$publicKeyPath = 'C:\Users\<UserName>\Documents\CodeCert.cer'
Export-Certificate -Cert $cert -FilePath $publicKeyPath


# If the terminal is closed, get the certificate again and assign it to the $cert variable
# Verify the friendly name of the certificate matches your code signing certificate
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.FriendlyName -eq 'Code Signing Cert' }
