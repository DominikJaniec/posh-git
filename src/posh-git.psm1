#######################################################################
# pwsh -NoProfile -NoExit -WorkingDirectory "$HOME\Repos\posh-git-no-prompt" -Command { function prompt { "custom-prompt> " }; Import-Module -Name "$HOME\Repos\posh-git-no-prompt\src\posh-git.psm1" }


param([bool]$ForcePoshGitPrompt, [bool]$UseLegacyTabExpansion, [bool]$EnableProxyFunctionExpansion)


Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

function __logScopePush {}
function __logScopePop {}
function __logEvent {}

# provides implementations of `__log*` methods:
# . "$HOME\Repos\EnvConfigs\_tools\profiler.autogen.ps1" `
    # -__PROFILER_SetDebugVerbose `
    # -__PROFILER_WriteOn_LogEvent


__logScopePush "no-prompt-req"

$Global:GitStatus = $null

__logScopePop


__logScopePush "posh-git.psm1"

__logScopePush "CheckRequirements"
if (Test-Path Env:\POSHGIT_ENABLE_STRICTMODE) {
    # Set strict mode to latest to help catch scripting errors in the module. This is done by the Pester tests.
    Set-StrictMode -Version Latest
}

__logEvent "executing CheckRequirements"
. $PSScriptRoot\CheckRequirements.ps1 > $null

function switchLogScope ($name) {
    __logScopePop
    __logScopePush $name
}


switchLogScope "ConsoleMode"
. $PSScriptRoot\ConsoleMode.ps1
switchLogScope "Utils"
. $PSScriptRoot\Utils.ps1
switchLogScope "AnsiUtils"
. $PSScriptRoot\AnsiUtils.ps1
switchLogScope "WindowTitle"
. $PSScriptRoot\WindowTitle.ps1
switchLogScope "PoshGitTypes"
. $PSScriptRoot\PoshGitTypes.ps1
switchLogScope "GitUtils"
. $PSScriptRoot\GitUtils.ps1
switchLogScope "GitPrompt"
. $PSScriptRoot\GitPrompt.ps1
switchLogScope "GitParamTabExpansion"
. $PSScriptRoot\GitParamTabExpansion.ps1
switchLogScope "GitTabExpansion"
. $PSScriptRoot\GitTabExpansion.ps1
switchLogScope "TortoiseGit"
. $PSScriptRoot\TortoiseGit.ps1

switchLogScope "IsAdmin"
$IsAdmin = Test-Administrator
__logScopePop


__logScopePush "prompt-setup"
# Get the default prompt definition.
$initialSessionState = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InitialSessionState
if (!$initialSessionState -or !$initialSessionState.PSObject.Properties.Match('Commands') -or !$initialSessionState.Commands['prompt']) {
    $defaultPromptDef = "`$(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + `$(Get-Location) + `$(if (`$nestedpromptlevel -ge 1) { '>>' }) + '> '"
}
else {
    $defaultPromptDef = $initialSessionState.Commands['prompt'].Definition
}

# The built-in posh-git prompt function in ScriptBlock form.
$GitPromptScriptBlock = {
    $origDollarQuestion = $global:?
    $origLastExitCode = $global:LASTEXITCODE

    if (!$global:GitPromptValues) {
        $global:GitPromptValues = [PoshGitPromptValues]::new()
    }

    $global:GitPromptValues.DollarQuestion = $origDollarQuestion
    $global:GitPromptValues.LastExitCode = $origLastExitCode
    $global:GitPromptValues.IsAdmin = $IsAdmin

    $settings = $global:GitPromptSettings

    if (!$settings) {
        return "<`$GitPromptSettings not found> "
    }

    if ($settings.DefaultPromptEnableTiming) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
    }

    if ($settings.SetEnvColumns) {
        # Set COLUMNS so git knows how wide the terminal is
        $Env:COLUMNS = $Host.UI.RawUI.WindowSize.Width
    }

    # Construct/write the prompt text
    $prompt = ''

    # Write default prompt prefix
    $prompt += Write-Prompt $settings.DefaultPromptPrefix.Expand()

    # Get the current path - formatted correctly
    $promptPath = $settings.DefaultPromptPath.Expand()

    # Write the delimited path and Git status summary information
    if ($settings.DefaultPromptWriteStatusFirst) {
        $prompt += Write-VcsStatus
        $prompt += Write-Prompt $settings.BeforePath.Expand()
        $prompt += Write-Prompt $promptPath
        $prompt += Write-Prompt $settings.AfterPath.Expand()
    }
    else {
        $prompt += Write-Prompt $settings.BeforePath.Expand()
        $prompt += Write-Prompt $promptPath
        $prompt += Write-Prompt $settings.AfterPath.Expand()
        $prompt += Write-VcsStatus
    }

    # Write default prompt before suffix text
    $prompt += Write-Prompt $settings.DefaultPromptBeforeSuffix.Expand()

    # If stopped in the debugger, the prompt needs to indicate that by writing default prompt debug
    if ((Test-Path Variable:/PSDebugContext) -or [runspace]::DefaultRunspace.Debugger.InBreakpoint) {
        $prompt += Write-Prompt $settings.DefaultPromptDebug.Expand()
    }

    # Get the prompt suffix text
    $promptSuffix = $settings.DefaultPromptSuffix.Expand()

    # When using Write-Host, we return a single space from this function to prevent PowerShell from displaying "PS>"
    # So to avoid two spaces at the end of the suffix, remove one here if it exists
    if (!$settings.AnsiConsole -and $promptSuffix.Text.EndsWith(' ')) {
        $promptSuffix.Text = $promptSuffix.Text.Substring(0, $promptSuffix.Text.Length - 1)
    }

    # This has to be *after* the call to Write-VcsStatus, which populates $global:GitStatus
    Set-WindowTitle $global:GitStatus $IsAdmin

    # If prompt timing enabled, write elapsed milliseconds
    if ($settings.DefaultPromptEnableTiming) {
        $timingInfo = [PoshGitTextSpan]::new($settings.DefaultPromptTimingFormat)
        $sw.Stop()
        $timingInfo.Text = $timingInfo.Text -f $sw.ElapsedMilliseconds
        $prompt += Write-Prompt $timingInfo
    }

    $prompt += Write-Prompt $promptSuffix

    # When using Write-Host, return at least a space to avoid "PS>" being unexpectedly displayed
    if (!$settings.AnsiConsole) {
        $prompt += " "
    }
    else {
        # If using ANSI, set this global to help debug ANSI issues
        $global:GitPromptValues.LastPrompt = EscapeAnsiString $prompt
    }

    $global:LASTEXITCODE = $origLastExitCode
    $prompt
}

$currentPromptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }

# If prompt matches pre-0.7 posh-git prompt, ignore it
$collapsedLegacyPrompt = '$realLASTEXITCODE = $LASTEXITCODE;Write-Host($pwd.ProviderPath) -nonewline;Write-VcsStatus;$global:LASTEXITCODE = $realLASTEXITCODE;return "> "'
if ($currentPromptDef -and (($currentPromptDef.Trim() -replace '[\r\n\t]+\s*',';') -eq $collapsedLegacyPrompt)) {
    Write-Warning 'Replacing old posh-git prompt. Did you copy profile.example.ps1 into $PROFILE?'
    $currentPromptDef = $null
}

if (!$currentPromptDef) {
    # HACK: If prompt is missing, create a global one we can overwrite with Set-Item
    function global:prompt { ' ' }
}

# If there is no prompt function or the prompt function is the default, replace the current prompt function definition
if ($ForcePoshGitPrompt -or !$currentPromptDef -or ($currentPromptDef -eq $defaultPromptDef)) {
    # Set the posh-git prompt as the default prompt
    Set-Item Function:\prompt -Value $GitPromptScriptBlock
}
__logScopePop


__logScopePush "module-setup"
# Install handler for removal/unload of the module
$ExecutionContext.SessionState.Module.OnRemove = {
    $global:VcsPromptStatuses = $global:VcsPromptStatuses | Where-Object { $_ -ne $PoshGitVcsPrompt }

    Reset-WindowTitle

    # Check if the posh-git prompt function itself has been replaced. If so, do not restore the prompt function
    $promptDef = if ($funcInfo = Get-Command prompt -ErrorAction SilentlyContinue) { $funcInfo.Definition }
    if ($promptDef -eq $GitPromptScriptBlock) {
        Set-Item Function:\prompt -Value ([scriptblock]::Create($defaultPromptDef))
        return
    }

    Write-Warning 'If your prompt function uses any posh-git commands, it will cause posh-git to be re-imported every time your prompt function is invoked.'
}

function Show-LogAllEvents () {
    $(__logShowAllEvents_WriteHost)
}

$exportModuleMemberParams = @{
    Function = @(
        'Show-LogAllEvents',
        'Add-PoshGitToProfile',
        'Expand-GitCommand',
        'Format-GitBranchName',
        'Get-GitBranchStatusColor',
        'Get-GitDirectory',
        'Get-GitStatus',
        'Get-PromptConnectionInfo',
        'Get-PromptPath',
        'New-GitPromptSettings',
        'Remove-GitBranch',
        'Remove-PoshGitFromProfile',
        'Update-AllBranches',
        'Write-GitStatus',
        'Write-GitBranchName',
        'Write-GitBranchStatus',
        'Write-GitIndexStatus',
        'Write-GitStashCount',
        'Write-GitWorkingDirStatus',
        'Write-GitWorkingDirStatusSummary',
        'Write-Prompt',
        'Write-VcsStatus',
        'TabExpansion',
        'tgit'
    )
    Variable = @(
        'GitPromptScriptBlock'
    )
}

Export-ModuleMember @exportModuleMemberParams
__logScopePop


__logScopePop
