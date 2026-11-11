# Installs or removes one winget package. Run by ansible.windows.win_powershell,
# which supplies $Ansible.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Id,

    [string]$Version = '',

    [ValidateSet('present', 'absent')]
    [string]$State = 'present',

    [string]$Source = 'winget'
)

$ErrorActionPreference = 'Stop'
$Ansible.Changed = $false

$winget = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    # Services and remote sessions do not get the per-user alias on PATH.
    $winget = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
}
if (-not $winget) {
    throw 'winget.exe was not found. It ships with Windows 11 and Windows Server 2025 or newer (App Installer).'
}
$exe = if ($winget -is [System.Management.Automation.CommandInfo]) { $winget.Source } else { $winget.FullName }

$common = @('--id', $Id, '--exact', '--source', $Source, '--accept-source-agreements', '--disable-interactivity')

$listArgs = @('list') + $common
if ($Version) { $listArgs += @('--version', $Version) }
& $exe @listArgs | Out-Null
$installed = $LASTEXITCODE -eq 0

if ($State -eq 'present' -and -not $installed) {
    $Ansible.Changed = $true
    if ($PSCmdlet.ShouldProcess($Id, 'winget install')) {
        $installArgs = @('install') + $common + @('--silent', '--scope', 'machine', '--accept-package-agreements')
        if ($Version) { $installArgs += @('--version', $Version) }
        $output = & $exe @installArgs 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "winget install $Id failed with exit code $LASTEXITCODE. $output"
        }
    }
}
elseif ($State -eq 'absent' -and $installed) {
    $Ansible.Changed = $true
    if ($PSCmdlet.ShouldProcess($Id, 'winget uninstall')) {
        $output = & $exe uninstall @common --silent 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "winget uninstall $Id failed with exit code $LASTEXITCODE. $output"
        }
    }
}
