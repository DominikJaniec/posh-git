#######################################################################
# pwsh -NoProfile -NoExit -WorkingDirectory "$HOME\Repos\posh-git-no-prompt" -Command { function prompt { "custom-prompt> " }; Import-Module -Name "$HOME\Repos\posh-git-no-prompt\src\posh-git-no-prompt.psm1" }

param([bool]$UseLegacyTabExpansion, [bool]$EnableProxyFunctionExpansion)


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
$script:GitVersion = [System.Version]"2.39.1"

__logScopePop


__logScopePush "posh-git.psm1"


__logScopePush "Utils"
. $PSScriptRoot\Utils.ps1
__logScopePop
__logScopePush "GitUtils"
. $PSScriptRoot\GitUtils.ps1
__logScopePop
__logScopePush "GitParamTabExpansion"
. $PSScriptRoot\GitParamTabExpansion.ps1
__logScopePop
__logScopePush "GitTabExpansion"
. $PSScriptRoot\GitTabExpansion.ps1
__logScopePop

__logScopePush "module-setup"
function Show-LogAllEvents () {
    $(__logShowAllEvents_WriteHost)
}

$exportModuleMemberParams = @{
    Function = @(
        'Show-LogAllEvents',
        'Add-PoshGitToProfile',
        'Expand-GitCommand',
        'Get-GitDirectory',
        'Get-GitStatus',
        'Get-PromptConnectionInfo',
        'Get-PromptPath',
        'Remove-GitBranch',
        'Remove-PoshGitFromProfile',
        'Update-AllBranches'
    )
}

Export-ModuleMember @exportModuleMemberParams
__logScopePop


__logScopePop
