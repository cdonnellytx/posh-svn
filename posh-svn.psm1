param([switch]$NoVersionWarn)

if (Get-Module posh-svn) { return }

$psv = $PSVersionTable.PSVersion

if ($psv.Major -lt 3 -and !$NoVersionWarn) {
    Write-Warning ("posh-svn support for PowerShell 2.0 is deprecated; you have version $($psv).`n" +
    "To download version 5.0, please visit https://www.microsoft.com/en-us/download/details.aspx?id=50395`n" +
    "For more information and to discuss this, please visit **TODO PR**`n" +
    "To suppress this warning, change your profile to include 'Import-Module posh-svn -Args `$true'.")
}

# Refer to svn application command via this, as we alias it.
$svn = $null

# & $PSScriptRoot\CheckVersion.ps1 > $null
New-TimingInfo -Name CheckVersion -Command {
    $Global:SvnMissing = $false

    $svn = Get-Command 'svn' -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue
    if (!$svn) {
        Write-Warning "svn application command could not be found. Please create an alias or add it to your PATH."
        $Global:SvnMissing = $true
        return
    }

    # HACK determine a minimum required version, 1.6.0 is a guess
    $requiredVersion = [Version]'1.6.0'
    if ([String](& $svn --version 2> $null) -match '(?<ver>\d+(?:\.\d+)+)') {
        $version = [Version]$Matches['ver']
    }
    if ($version -lt $requiredVersion) {
        Write-Warning "posh-svn requires Subversion $requiredVersion or better. You have $version."
        return
    }
}

@('SvnUtils', 'SvnPrompt', 'SvnTabExpansion') |
    ForEach-Object {
        New-TimingInfo -Name $_ -Command {
            try
            {
                # @see https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
                $ExecutionContext.InvokeCommand.InvokeScript(
                    $false,
                    [scriptblock]::Create([io.file]::ReadAllText("${PSScriptRoot}\${_}.ps1", [Text.Encoding]::UTF8)),
                    $null,
                    $null
                );
            }
            catch
            {
                $count = 0
                $errors = for ($ex = $_.Exception; $ex; $ex = $ex.InnerException) {
                    if ($count++ -gt 0) { "`n -----> " + $ex.ErrorRecord } else { $ex.ErrorRecord }
                    "Stack trace:"
                    $ex.ErrorRecord.ScriptStackTrace
                }

                throw "Cannot process script '${fullName}':`n$errors"
            }            
        } 
    }

#. $PSScriptRoot\SvnUtils.ps1
#. $PSScriptRoot\SvnPrompt.ps1
#. $PSScriptRoot\SvnTabExpansion.ps1


Export-ModuleMember -Function @(
    'Write-SvnStatus',
    'Get-SvnStatus',
    'Get-SvnInfo',
    'TabExpansion',
    'tsvn',
    'Invoke-Svn'
) -Alias @('svn')


