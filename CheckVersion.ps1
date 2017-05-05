$Global:SvnMissing = $false

if (!(Get-Command svn -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Warning "svn command could not be found. Please create an alias or add it to your PATH."
    $Global:SvnMissing = $true
    return
}

# HACK determine a minimum required version, 1.6.0 is a guess
$requiredVersion = [Version]'1.6.0'
if ([String](svn --version 2> $null) -match '(?<ver>\d+(?:\.\d+)+)') {
    $version = [Version]$Matches['ver']
}
if ($version -lt $requiredVersion) {
    Write-Warning "posh-svn requires Subversion $requiredVersion or better. You have $version."
    $false
} else {
    $true
}
