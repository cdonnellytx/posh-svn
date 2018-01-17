param([switch] $NoVersionWarn)

$psv = $PSVersionTable.PSVersion

if ($psv.Major -lt 3 -and !$NoVersionWarn) {
    Write-Warning ("posh-svn support for PowerShell 2.0 is deprecated; you have version $($psv).`n" +
    "To download version 5.0, please visit https://www.microsoft.com/en-us/download/details.aspx?id=50395`n" +
    "For more information and to discuss this, please visit **TODO PR**`n" +
    "To suppress this warning, change your profile to include 'Import-Module posh-svn -Args `$true'.")
}

$Scripts = @('CheckVersion', 'SvnUtils', 'SvnPrompt', 'SvnTabExpansion')
if ($psv.Major -ge 3) {
    # PowerShell 3.0 and later
    $Scripts | ForEach-Object {
        $fullName = Join-Path $PSScriptRoot "${_}.ps1"
        try {
            # Invoke scripts dynamically, as dot sourcing is expensive.
            # @see https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
            $ExecutionContext.InvokeCommand.InvokeScript(
                $false,
                [scriptblock]::Create([io.file]::ReadAllText($fullName, [Text.Encoding]::UTF8)),
                $null,
                $null
            );
        }
        catch {
            $count = 0
            $errors = for ($ex = $_.Exception; $ex; $ex = $ex.InnerException) {
                if ($count++ -gt 0) { "`n -----> " + $ex.ErrorRecord } else { $ex.ErrorRecord }
                "Stack trace:"
                $ex.ErrorRecord.ScriptStackTrace
            }
            Write-Error "Cannot process script '${fullName}':`n${errors}"
        }
    }
}
else {
    # PowerShell 2.0

    # $PSScriptRoot was added in 3.0
    # @see https://stackoverflow.com/questions/3667238/how-can-i-get-the-file-system-location-of-a-powershell-script
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    $Scripts | ForEach-Object {
        $fullName = Join-Path $PSScriptRoot "${_}.ps1"
        try {
            # Use "normal" dot sourcing, as the InvokeScript() overload we need is not in PowerShell 2.0.
            . $fullName
        }
        catch {
            $errors = @()
            for ($ex = $err.Exception; $ex; $ex = $ex.InnerException) {
                $errors += $ex
            }
            Write-Error "Cannot process script '${fullName}':`n${errors}"
        }
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
