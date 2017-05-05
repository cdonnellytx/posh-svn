param([switch]$NoVersionWarn)

if (Get-Module posh-svn) { return }

$psv = $PSVersionTable.PSVersion

if ($psv.Major -lt 3 -and !$NoVersionWarn) {
    Write-Warning ("posh-svn support for PowerShell 2.0 is deprecated; you have version $($psv).`n" +
    "To download version 5.0, please visit https://www.microsoft.com/en-us/download/details.aspx?id=50395`n" +
    "For more information and to discuss this, please visit **TODO PR**`n" +
    "To suppress this warning, change your profile to include 'Import-Module posh-svn -Args `$true'.")
}

& $PSScriptRoot\CheckVersion.ps1 > $null

. $PSScriptRoot\SvnUtils.ps1
. $PSScriptRoot\SvnPrompt.ps1
. $PSScriptRoot\SvnTabExpansion.ps1

Export-ModuleMember -Function @(
    'Write-SvnStatus',
    'Get-SvnStatus',
    'Get-SvnInfo',
    'TabExpansion',
    'tsvn'
)

