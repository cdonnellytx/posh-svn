function Get-SvnDirectory() {
    $pathInfo = Microsoft.PowerShell.Management\Get-Location
    if (!$pathInfo -or ($pathInfo.Provider.Name -ne 'FileSystem')) {
        return $null
    }
    else {
        $currentDir = Get-Item $pathInfo -Force
        while ($currentDir) {
            $svnDirPath = Join-Path $currentDir.FullName .svn
            if (Test-Path -LiteralPath $svnDirPath -PathType Container) {
                return $svnDirPath
            }

            # Handle the worktree case where .git is a file
            if (Test-Path -LiteralPath $svnDirPath -PathType Leaf) {
                $svnDirPath = Invoke-Utf8ConsoleCommand { git rev-parse --git-dir 2>$null }
                if ($svnDirPath) {
                    return $svnDirPath
                }
            }

            $currentDir = $currentDir.Parent
        }
    }
}

function Get-SvnInfo {
    [OutputType([Hashtable])]
    param (
        [ValidateNotNullOrEmpty()]
        [string] $Path = '.'
    )
    $result = @{}
    try {
    svn info $Path 2> $null |
        Where-Object { $_ } |       # eat blank lines
        ForEach-Object {
            if ($_ -imatch '^(?<Name>[^:]*?)\s*:\s*(?<Value>.*?)\s*$') {
                $name = $Matches.Name;
                $value = switch ($name) {
                    'URL' { [Uri] $Matches.Value }
                    default { $Matches.Value }
                }
                $result.Add($name, $value)
            } else {
                throw "line did not match expected pattern: '$_'"
            }
        }
    return $result
    }
catch {
    throw "argh: $_"
}
}

function Get-SvnStatus($svnDir = (Get-SvnDirectory)) {
    $settings = $Global:SvnPromptSettings
    $enabled = (-not $settings) -or $settings.EnablePromptStatus
    if ($enabled -and $svnDir) {
        $untracked = 0
        $added = 0
        $ignored = 0
        $modified = 0
        $replaced = 0
        $deleted = 0
        $missing = 0
        $conflicted = 0
        $external = 0
        $obstructed = 0
        $incoming = 0
        $incomingRevision = $null
        $info = Get-SvnInfo $svnDir
        $branch = Get-SvnBranchName $info
        $hostName = ([System.Uri]$info['URL']).Host #URL: http://svnserver/trunk/test

        $statusArgs = @()

        # EnableRemoteStatus: defaults to true
        $showRemote = (-not $settings) -or $settings.EnableRemoteStatus
        if ($showRemote -and (Test-Connection -computername $hostName -Quiet -Count 1 -BufferSize 1)) {
            $statusArgs += '--show-updates'
        }

        # EnableExternalFileStatus: defaults to false
        $showExternalFiles = $settings -and $settings.EnableExternalFileStatus
        if (!$showExternalFiles) {
            $statusArgs += '--ignore-externals'
        }

        svn status $statusArgs | ForEach-Object {
            if ($_ -eq "")
            {
                # blank line between externals
            }
            elseif ($_.StartsWith("Status against revision:"))
            {
                if ($incomingRevision -eq $null)
                {
                    $incomingRevision = [Int]$_.Replace("Status against revision:", "")
                }
            }
            elseif ($_.StartsWith("Performing status on external item at"))
            {
                # External
                # ignore for now.
            }
            else
            {
                switch($_[0]) {
                    'A' { $added++; break; }
                    'C' { $conflicted++; break; }
                    'D' { $deleted++; break; }
                    'I' { $ignored++; break; }
                    'M' { $modified++; break; }
                    'R' { $replaced++; break; }
                    'X' { $external++; break; }
                    '?' { $untracked++; break; }
                    '!' { $missing++; break; }
                    '~' { $obstructed++; break; }
                }
                switch($_[1]) {
                    'A' { $added++; break; }
                    'C' { $conflicted++; break; }
                    'D' { $deleted++; break; }
                    'I' { $ignored++; break; }
                    'M' { $modified++; break; }
                    'R' { $replaced++; break; }
                    'X' { $external++; break; }
                    '?' { $untracked++; break; }
                    '!' { $missing++; break; }
                    '~' { $obstructed++; break; }
                }
                switch($_[4]) {
                    'X' { $external++; break; }
                }
                switch($_[6]) {
                    'C' { $conflicted++; break; }
                }
                switch($_[8]) {
                    '*' { $incoming++; break; }
                }
            }
        }


        $title = ''
        if ($settings.EnableWindowTitle)
        {
            $repoName = Split-Path -Leaf (Split-Path $svnDir)
            $prefix = if ($settings.EnableWindowTitle -is [string]) { $settings.EnableWindowTitle } else { '' }
            $title = "${prefix}${repoName} [$($branch)]"
        }
        
        return New-Object PSObject -Property @{
            SvnDir = $svnDir
            Title = $title;
            Added = $added;
            Modified = $modified + $replaced;
            Deleted = $deleted;
            HasIndex = [bool]($added -or $modified -or $replaced -or $deleted)
            Untracked = $untracked;
            Missing = $missing;
            Obstructed = $obstructed;
            Conflicted = $conflicted;
            HasWorking = [bool]($untracked -or $missing -or $obstructed -or $conflicted)
            External = $external;
            Incoming = $incoming
            Url = $info.Url
            Branch = $branch;
            Revision = $info.Revision;
            IncomingRevision = $incomingRevision;
        }
    }
}

function Get-SvnBranchName($info) {
    if (!$info -or !$info.Url) { return }

    $pathBits = $info.Url.AbsolutePath.Split("/", [StringSplitOptions]::RemoveEmptyEntries)

    for ($i = 0; $i -lt $pathBits.length; $i++) {
        switch -regex ($pathBits[$i]) {
            "trunk" {
                return $pathBits[$i]
            }
            "branches|tags" {
                $next = $i + 1
                if ($next -lt $pathBits.Length) {
                    return $pathBits[$next]
                }
            }
        }
    }

    # Just return the relative URL for the root path.
    # (In practice we just do current directory so don't bother seeing if our path is the root)
    $rootInfo = Get-SvnInfo $info['Working Copy Root Path']
    return $rootInfo['Relative URL']
}

function tsvn {
  if($args) {
    if($args[0] -eq "help") {
      #I don't like the built in help behaviour!
      $tsvnCommands.keys | Sort-Object | ForEach-Object { write-host $_ }

      return
    }

    $newArgs = @()
    $newArgs += "/command:" + $args[0]

    $cmd = $tsvnCommands[$args[0]]
    if($cmd -and $cmd.useCurrentDirectory) {
       $newArgs += "/path:."
    }

    if($args.length -gt 1) {
      $args[1..$args.length] | % { $newArgs += $_ }
    }

    tortoiseproc $newArgs
  }
}

function Get-AliasPattern($exe) {
  $aliases = @($exe) + @(Get-Alias | where { $_.Definition -eq $exe } | select -Exp Name)
  "($($aliases -join '|'))"
}
