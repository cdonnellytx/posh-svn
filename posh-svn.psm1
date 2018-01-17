param([switch] $NoVersionWarn)

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

if ($psv.Major -ge 3) {
    function Invoke-ProfileScript([string] $fullName) {
        # @see https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
        $ExecutionContext.InvokeCommand.InvokeScript(
            $false,
            [scriptblock]::Create([io.file]::ReadAllText($fullName, [Text.Encoding]::UTF8)),
            $null,
            $null
        );
    }

    function Get-ProfileScriptErrors([System.Management.Automation.ErrorRecord] $err) {
        $count = 0
        for ($ex = $_.Exception; $ex; $ex = $ex.InnerException) {
            if ($count++ -gt 0) { "`n -----> " + $ex.ErrorRecord } else { $ex.ErrorRecord }
            "Stack trace:"
            $ex.ErrorRecord.ScriptStackTrace
        }
    }
}
else {
    # PowerShell 2.0: use the cut-down version
    function Invoke-ProfileScript([string] $fullName) {
        . $fullName
    }

    function Get-ProfileScriptErrors([System.Management.Automation.ErrorRecord] $err) {
        $errors = @()
        for ($ex = $err.Exception; $ex; $ex = $ex.InnerException) {
            $errors += $ex
        }
        return $errors
    }
}

@('CheckVersion', 'SvnUtils', 'SvnPrompt', 'SvnTabExpansion') |
    ForEach-Object {
        $fullName = Join-Path '.' "${_}.ps1"
        try {
            Invoke-ProfileScript $fullName
        }
        catch {
            $errors = Get-ProfileScriptErrors $_
            Write-Error "Cannot process script '${fullName}':`n${errors}"
        }
    }

Export-ModuleMember -Function @(
    'Write-SvnStatus',
    'Get-SvnStatus',
    'Get-SvnInfo',
    'TabExpansion',
    'tsvn',
    'Invoke-Svn'
) -Alias @(
    'svn'
)


