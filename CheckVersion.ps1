$Global:SvnMissing = $false

$svn = Get-Command 'svn' -CommandType Application -TotalCount 1 -ErrorAction SilentlyContinue
if (!$svn) {
    Write-Warning "svn application command could not be found. Please add it to your PATH."
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

