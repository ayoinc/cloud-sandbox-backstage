<powershell>
# EC2 user data: opens WinRM over HTTPS with a self-signed certificate so that
# Packer can connect to the build instance.
$ErrorActionPreference = 'Stop'

$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation 'Cert:\LocalMachine\My'
Get-ChildItem -Path WSMan:\localhost\Listener | Remove-Item -Recurse -Force
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force | Out-Null

Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\MaxTimeoutms -Value 1800000

New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow | Out-Null
Restart-Service -Name WinRM
</powershell>
