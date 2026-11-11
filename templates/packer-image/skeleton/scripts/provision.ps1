# Installs the software baked into the ${{ values.name }} image. Packer runs
# this as an administrator on the temporary build machine.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
{%- if values.custom_packages | length %}

# Chocolatey installs the additional packages.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$installer = Join-Path $env:TEMP 'install-chocolatey.ps1'
Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -OutFile $installer -UseBasicParsing
& $installer
Remove-Item $installer
$choco = Join-Path $env:ProgramData 'chocolatey\bin\choco.exe'
& $choco install --yes --no-progress{% for pkg in values.custom_packages %} ${{ pkg }}{% endfor %}
if ($LASTEXITCODE -ne 0) { throw "choco install failed with exit code $LASTEXITCODE" }
{%- endif %}
{%- if values.install_docker %}

# Docker Engine for Windows containers; the restart after this script
# completes the Containers feature.
Install-WindowsFeature -Name Containers | Out-Null
$dockerInstaller = Join-Path $env:TEMP 'install-docker-ce.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1' -OutFile $dockerInstaller -UseBasicParsing
& $dockerInstaller -NoRestart
Remove-Item $dockerInstaller
{%- endif %}
{%- if values.install_ansible %}

# Ansible does not run on Windows. The image is prepared to be managed by
# Ansible instead: OpenSSH Server is installed and started at boot.
Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null
Set-Service -Name sshd -StartupType Automatic
New-NetFirewallRule -Name 'sshd' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null
{%- endif %}

Write-Output 'Provisioning complete.'
