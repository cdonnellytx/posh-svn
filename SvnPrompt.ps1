$global:SvnPromptSettings = [PSCustomObject]@{
    DefaultForegroundColor                  = $null
    DefaultBackgroundColor                  = $null

    BeforeText                              = ' ['
    BeforeForegroundColor                   = [ConsoleColor]::Yellow
    BeforeBackgroundColor                   = $null

    DelimText                               = ' |'
    DelimForegroundColor                    = [ConsoleColor]::Yellow
    DelimBackgroundColor                    = $null

    AfterText                               = ']'
    AfterForegroundColor                    = [ConsoleColor]::Yellow
    AfterBackgroundColor                    = $null

    FileAddedText                           = '+'
    FileModifiedText                        = '~'
    FileRemovedText                         = '-'
    FileConflictedText                      = '!'

    LocalDefaultStatusSymbol                = $null
    LocalDefaultStatusForegroundColor       = [ConsoleColor]::DarkGreen
    LocalDefaultStatusBackgroundColor       = $null

    LocalWorkingStatusSymbol                = '!'
    LocalWorkingStatusForegroundColor       = [ConsoleColor]::DarkRed
    LocalWorkingStatusBackgroundColor       = $null

    LocalStagedStatusSymbol                 = '~'
    LocalStagedStatusForegroundColor        = [ConsoleColor]::Cyan
    LocalStagedStatusBackgroundColor        = $null

    BranchForegroundColor                   = [ConsoleColor]::Cyan
    BranchBackgroundColor                   = $null

    RevisionText                            = '@'
    RevisionForegroundColor                 = [ConsoleColor]::DarkGray
    RevisionBackgroundColor                 = $null

    IndexForegroundColor                    = [ConsoleColor]::DarkGreen
    IndexBackgroundColor                    = $null

    WorkingForegroundColor                  = [ConsoleColor]::DarkRed
    WorkingBackgroundColor                  = $null

    ExternalStatusSymbol                    = [char]0x2190 # arrow right
    ExternalForegroundColor                 = [ConsoleColor]::DarkGray
    ExternalBackgroundColor                 = $null

    IncomingStatusSymbol                    = [char]0x2193 # Down arrow
    IncomingForegroundColor                 = [ConsoleColor]::Red
    IncomingBackgroundColor                 = $null

    ShowStatusWhenZero                      = $true

    EnablePromptStatus                      = !$Global:SvnMissing

    EnableRemoteStatus                      = $true   # show remote server status
    EnableExternalFileStatus                = $false  # include files from externals in counts
    ShowExternals                           = $true

    EnableWindowTitle                       = 'svn ~ '
}

$WindowTitleSupported = $true
if (Get-Module NuGet) {
    $WindowTitleSupported = $false
}

function Write-Prompt {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $false)]
        [Nullable[ConsoleColor]] $ForegroundColor = $SvnPromptSettings.DefaultForegroundColor,

        [Parameter(Mandatory = $false)]
        [Nullable[ConsoleColor]] $BackgroundColor = $SvnPromptSettings.DefaultBackgroundColor
    )

    $writeHostParams = @{
        Object    = $Object;
        NoNewLine = $true;
    }

    if (Test-ConsoleColor $BackgroundColor) {
        $writeHostParams.BackgroundColor = $BackgroundColor
    }

    if (Test-ConsoleColor $ForegroundColor) {
        $writeHostParams.ForegroundColor = $ForegroundColor
    }

    Write-Host @writeHostParams
}

function Write-SvnStatus($status) {
    $s = $global:SvnPromptSettings
    if ($status -and $s) {
        Write-Prompt $s.BeforeText -BackgroundColor $s.BeforeBackgroundColor -ForegroundColor $s.BeforeForegroundColor
        Write-Prompt $status.Branch -BackgroundColor $s.BranchBackgroundColor -ForegroundColor $s.BranchForegroundColor
        Write-Prompt "$($s.RevisionText)$($status.Revision)" -BackgroundColor $s.RevisionBackgroundColor -ForegroundColor $s.RevisionForegroundColor

        if ($status.HasIndex) {
            if ($s.ShowStatusWhenZero -or $status.Added) {
                Write-Prompt " $($s.FileAddedText)$($status.Added)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if ($s.ShowStatusWhenZero -or $status.Modified) {
                Write-Prompt " $($s.FileModifiedText)$($status.Modified)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
            if ($s.ShowStatusWhenZero -or $status.Deleted) {
                Write-Prompt " $($s.FileRemovedText)$($status.Deleted)" -BackgroundColor $s.IndexBackgroundColor -ForegroundColor $s.IndexForegroundColor
            }
        }

        if ($status.HasWorking) {
            if ($status.HasIndex) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }

            if ($status.Untracked) {
                Write-Prompt " $($s.FileAddedText)$($status.Untracked)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Missing) {
                Write-Prompt " $($s.FileRemovedText)$($status.Missing)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }

            if ($status.Conflicted) {
                Write-Prompt " $($s.FileConflictedText)$($status.Conflicted)" -BackgroundColor $s.WorkingBackgroundColor -ForegroundColor $s.WorkingForegroundColor
            }
        }

        if ($status.Incoming) {
            Write-Prompt " $($s.IncomingStatusSymbol)$($status.Incoming)" -BackgroundColor $s.IncomingBackgroundColor -ForegroundColor $s.IncomingForegroundColor
            Write-Prompt "$($s.RevisionText)$($status.IncomingRevision)" -BackgroundColor $s.RevisionBackgroundColor -ForegroundColor $s.RevisionForegroundColor
        }

        if ($status.HasIndex) {
            # We have uncommitted files
            $localStatusSymbol          = $s.LocalStagedStatusSymbol
            $localStatusBackgroundColor = $s.LocalStagedStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalStagedStatusForegroundColor
        }
        elseif ($status.HasWorking) {
            # We have uncommitted files
            $localStatusSymbol          = $s.LocalWorkingStatusSymbol
            $localStatusBackgroundColor = $s.LocalWorkingStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalWorkingStatusForegroundColor
        }
        else {
            # No uncommited changes
            $localStatusSymbol          = $s.LocalDefaultStatusSymbol
            $localStatusBackgroundColor = $s.LocalDefaultStatusBackgroundColor
            $localStatusForegroundColor = $s.LocalDefaultStatusForegroundColor
        }

        if ($s.ShowExternals -and $status.External) {
            if ($status.HasWorking -or $status.HasIndex) {
                Write-Prompt $s.DelimText -BackgroundColor $s.DelimBackgroundColor -ForegroundColor $s.DelimForegroundColor
            }

            Write-Prompt " $($s.ExternalStatusSymbol)$($status.External)" -BackgroundColor $s.ExternalBackgroundColor -ForegroundColor $s.ExternalForegroundColor
        }

        if ($localStatusSymbol) {
            Write-Prompt (" {0}" -f $localStatusSymbol) -BackgroundColor $localStatusBackgroundColor -ForegroundColor $localStatusForegroundColor
        }

        Write-Prompt $s.AfterText -BackgroundColor $s.AfterBackgroundColor -ForegroundColor $s.AfterForegroundColor

        if ($WindowTitleSupported -and $status.Title) {
            $Global:CurrentWindowTitle += ' ~ ' + $status.Title
        }
    }
}

# Should match https://github.com/dahlbyk/posh-git/blob/master/GitPrompt.ps1
if (!(Test-Path Variable:Global:VcsPromptStatuses)) {
    $Global:VcsPromptStatuses = @()
}

# Scriptblock that will execute for write-vcsstatus
$PoshSvnVcsPrompt = {
    $Global:SvnStatus = Get-SvnStatus
    Write-SvnStatus $SvnStatus
}

$Global:VcsPromptStatuses += $PoshSvnVcsPrompt
$ExecutionContext.SessionState.Module.OnRemove = {
    $c = $Global:VcsPromptStatuses.Count
    $global:VcsPromptStatuses = @( $global:VcsPromptStatuses | Where-Object { $_ -ne $PoshSvnVcsPrompt -and $_ -inotmatch '\bWrite-SvnStatus\b' } ) # cdonnelly 2017-08-01: if the script is redefined in a different module

    if ($c -ne 1 + $Global:VcsPromptStatuses.Count) {
        Write-Warning "posh-svn: did not remove prompt"
    }
}
