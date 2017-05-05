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
    Try {
        $info = svn info 2> $null
        return $info
    }
    Catch
    {
        return $_.Exception.Message
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
        $incomingRevision = 0
        $branchInfo = Get-SvnBranchInfo $svnDir
        $info = Get-SvnInfo
        $hostName = ([System.Uri]$info[2].Replace("URL: ", "")).Host #URL: http://svnserver/trunk/test

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

        $status = svn status $statusArgs

        foreach($line in $status) {
            if ($line.StartsWith("Status"))
            {
                $incomingRevision = [Int]$line.Replace("Status against revision:", "")
            }
            else
            {
                switch($line[0]) {
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
                switch($line[4]) {
                    'X' { $external++; break; }
                }
                switch($line[6]) {
                    'C' { $conflicted++; break; }
                }
                switch($line[8]) {
                    '*' { $incoming++; break; }
                }
            }
        }

        return @{"Untracked" = $untracked;
                "Added" = $added;
                "Modified" = $modified + $replaced;
                "Deleted" = $deleted;
                "Missing" = $missing;
                "Conflicted" = $conflicted + $obstructed;
                "External" = $external;
                "Incoming" = $incoming
                "Branch" = $branchInfo.Branch;
                "Revision" = $branchInfo.Revision;
                "IncomingRevision" = $incomingRevision;}
    }
}

function Get-SvnBranchInfo($svnDir = $(Get-SvnDirectory)) {
    if (!$svnDir) { return }

    $info = Get-SvnInfo
    $url = $info[3].Replace("Relative URL: ^/", "") #Relative URL: ^/trunk/test
    $revision = $info[6].Replace("Revision: ", "") #Revision: 1234

    $pathBits = $url.Split("/", [StringSplitOptions]::RemoveEmptyEntries)

    $branch = 'UNKNOWN'
    for ($i = 0; $i -lt $pathBits.length; $i++) {
        switch -regex ($pathBits[$i]) {
            "trunk" {
                $branch = $pathBits[$i]
                break
            }
            "branches|tags" {
                $next = $i + 1
                if ($next -lt $pathBits.Length) {
                    $branch = $pathBits[$next]
                    break
                }
            }
        }
    }

    return @{
        "Branch" = $branch
        "Revision" = $revision
    }
}

function tsvn {
  if($args) {
    if($args[0] -eq "help") {
      #I don't like the built in help behaviour!
      $tsvnCommands.keys | sort | % { write-host $_ }

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
