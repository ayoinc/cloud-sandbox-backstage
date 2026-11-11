# Connecting

{%- if values.connection == 'winrm' %}
## WinRM over HTTPS

Each host needs an HTTPS listener with a server-authentication certificate
whose subject or subject alternative name is the name in the inventory.

With an enterprise CA and certificate auto-enrolment, create the listener from
the enrolled certificate. In an elevated PowerShell on the host:

```powershell
$fqdn = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName
$cert = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -match $fqdn -and $_.EnhancedKeyUsageList.FriendlyName -contains 'Server Authentication' } |
    Sort-Object NotAfter -Descending | Select-Object -First 1

Enable-PSRemoting -Force
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

In a domain, do this once with Group Policy instead of per host.

The baseline role keeps port 5986 open and leaves the HTTP listener on 5985
closed in the firewall.

### Trusting the certificate

Validation is on. If the listener certificates come from an internal CA, give
Ansible the CA bundle in `inventory/group_vars/windows/main.yml`:

```yaml
ansible_winrm_ca_trust_path: /etc/ssl/certs/corp-ca.pem
```

Do not switch validation off; without it the connection can be intercepted.
{%- if values.winrmTransport == 'kerberos' %}

### Kerberos

On the control machine:

```bash
# Debian, Ubuntu
sudo apt-get install krb5-user libkrb5-dev gcc python3-dev
# Enterprise Linux, Fedora
sudo dnf install krb5-workstation krb5-devel gcc python3-devel

pip install "pywinrm[kerberos]==0.5.0"
kinit svc-ansible@CORP.INTERNAL
```

`/etc/krb5.conf` must know the realm, or find its domain controllers through
DNS. The realm is written in upper case. Inventory names must be the hosts'
real DNS names, because the service ticket is issued for `HTTP/<name>`.

With a valid ticket, leave `vault_windows_password` out of the vault and
nothing secret is stored at all.
{%- else %}

### NTLM

NTLM authenticates local accounts. The exchange is protected by the HTTPS
listener. Use a dedicated local administrator with a long random password,
different on every host if you can (Windows LAPS manages that well), and keep
it in the vault.
{%- endif %}
{%- else %}
## OpenSSH

In an elevated PowerShell on each host:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

# Ansible needs PowerShell, not cmd, as the shell
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -PropertyType String -Force `
    -Value C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Authorise your public key. For members of the Administrators group, Windows
reads one shared file:

```powershell
Add-Content -Path C:\ProgramData\ssh\administrators_authorized_keys -Value 'ssh-ed25519 AAAA... you@control'
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F'
```

Then switch password logins off in `C:\ProgramData\ssh\sshd_config`
(`PasswordAuthentication no`) and restart `sshd`.

On the control machine, add the hosts' keys to `known_hosts` from a network
you trust; host key checking is on:

```bash
ssh-keyscan -t ed25519 <host> >> ~/.ssh/known_hosts
```

The baseline role keeps port 22 open in Windows Firewall.
{%- endif %}

## Test the connection

```bash
ansible windows -m ansible.windows.win_ping --ask-vault-pass
ansible windows -m ansible.windows.setup -a 'gather_subset=min' --ask-vault-pass
```

## Common errors

| Message | Cause |
| --- | --- |
{%- if values.connection == 'winrm' %}
| `certificate verify failed` | The listener's certificate does not chain to a trusted CA, or its name differs from the inventory name |
| `Server not found in Kerberos database` | The inventory name is not the host's DNS name, or the SPN `HTTP/<name>` is missing |
| `the specified credentials were rejected by the server` | Wrong account or password, or the account is not a local administrator |
| `Connection refused` on 5986 | No HTTPS listener, or the firewall rule is missing |
{%- else %}
| `Permission denied (publickey)` | The key is not in `administrators_authorized_keys`, or that file's permissions are too open |
| Tasks fail with shell syntax errors | The default shell is still cmd; set `DefaultShell` as above |
| `Host key verification failed` | The host is not in `known_hosts` |
{%- endif %}
