@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'posh-svn.psm1'

# Version number of this module.
ModuleVersion = '0.7.0'

# ID used to uniquely identify this module
GUID = 'f18820b6-2e02-41b4-afc5-de886bb1b848'

# Author of this module
Author = 'Matt Bishop, Jeremy Skinner and contributors'

# Description of the functionality provided by this module
Description = 'Provides prompt with Subversion status summary information and tab completion for Subversion commands, parameters, remotes and branch names.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess.
# This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('svn', 'prompt', 'tab', 'tab-completion', 'tab-expansion', 'tabexpansion')

        # A URL to the license for this module.
       # LicenseUri = 'https://github.com/imobile3/posh-svn/blob/v0.7.1/LICENSE.txt'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/imobile3/posh-svn'

        # ReleaseNotes of this module
        #ReleaseNotes = 'https://github.com/imobile3/posh-svn/blob/v0.7.1/CHANGELOG.md'
    }

}

}
