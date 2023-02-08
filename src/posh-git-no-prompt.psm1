#######################################################################
# pwsh -NoProfile -NoExit -WorkingDirectory "$HOME\Repos\posh-git" -Command { function prompt { "custom-prompt> " }; Import-Module -Name "$HOME\Repos\posh-git\src\posh-git-no-prompt.psm1" }

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


__logScopePush "no-prompt-ctx"

$global:GitStatus = $null
$global:GitMissing = $false
$script:GitCygwin = $false

if ($Env:GitFunctionsCompletion -eq $true) {
    $EnableProxyFunctionExpansion = $true
}

__logScopePop


__logScopePush "posh-git.psm1"

__logScopePush "CheckRequirements"
if ($null -eq $Env:GitVersion) {
    . $PSScriptRoot\CheckRequirements.ps1
}
else {
    $script:GitVersion = $Env:GitVersion
    __logEvent "GitVersion from environment: $GitVersion"
}
__logScopePop

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
