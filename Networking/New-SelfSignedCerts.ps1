# Create self signed root Cert 
$params = @{
    Type              = 'Custom'
    Subject           = 'CN=P2SRootCert'
    KeySpec           = 'Signature'
    KeyExportPolicy   = 'Exportable'
    KeyUsage          = 'CertSign'
    KeyUsageProperty  = 'Sign'
    KeyLength         = 2048
    HashAlgorithm     = 'sha256'
    NotAfter          = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
}
$cert = New-SelfSignedCertificate @params

# Create self signed client Cert
$params = @{
    Type              = 'Custom'
    Subject           = 'CN=P2SClientCert'
    DnsName           = 'P2SClientCert'
    KeySpec           = 'Signature'
    KeyExportPolicy   = 'Exportable'
    KeyLength         = 2048
    HashAlgorithm     = 'sha256'
    NotAfter          = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
    Signer            = $cert
    TextExtension     = @(
        '2.5.29.37={text}1.3.6.1.5.5.7.3.2')
}
New-SelfSignedCertificate @params


# If you close the PowerShell window, set the $cert variable.
# Verify $_.Subject -eq "<SubjectName>" matches the certificate you created
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Subject -eq "CN=P2SRootCert" }
# run the "Create self signed client Cert" steps above to export the client cert
