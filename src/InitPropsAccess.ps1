param ($DefaultProps)

__logEvent "managing `$global:PoshGit_InitProps"

function script:Get-InitPropsSkipPrompt () {
    return $global:PoshGit_InitProps.DisablePoshGitPrompt `
        -and -not $global:PoshGit_InitProps.ForcePoshGitPrompt
}

function script:Get-InitPropsExtension ([string]$Name) {
    $exts = $global:PoshGit_InitProps.LocalGitExtensions

    $keys = , $Name
    $prefix = "git-"
    $keys += $Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) `
        ? $Name.Substring($prefix.Length) `
        : $prefix + $Name

    $matched = $exts.Keys `
    | Where-Object { $_ -in $keys }
    $matched = @($matched)

    if ($matched.Length -eq 0) {
        return $null
    }
    if ($matched.Length -eq 1) {
        return $exts[$matched[0]]
    }

    $values = @($matched) `
    | ForEach-Object { $exts[$_] } `
    | Select-Object -Unique
    $values = @($values)

    if ($values.Length -eq 1) {
        return $values[0]
    }

    $keys = $keys -join ", "
    throw "ambiguous configuration with: $keys"
}

__logScopePush "looking for PoshGit-InitProps"
if (Test-Path variable:global:PoshGit_InitProps) {
    foreach ($key in $DefaultProps.Keys) {
        if (-not $global:PoshGit_InitProps.ContainsKey($key)) {
            __logEvent "using Default[$key]"
            $global:PoshGit_InitProps[$key] = `
                $DefaultProps[$key]
        }
        else {
            $val = $global:PoshGit_InitProps[$key]
            if ($key -eq "LocalGitExtensions") {
                $val = $val | ConvertTo-Json -Compress
            }

            __logEvent "`$InitProps[$key] = $val"
        }
    }
}
else {
    $global:PoshGit_InitProps = `
        $DefaultProps.Clone()
}
__logScopePop

__logScopePush "old-module-param"
function Get-ParamOverrideOf ($ParamValue, $ParamName, $GlobalName = $null) {
    $GlobalName ??= $ParamName

    if ($ParamValue -eq $true) {
        __logEvent "ArgumentList `$'$ParamName' was set"
        $props = "global:PoshGit_InitProps"
        $propName = $GlobalName

        Write-Verbose "The 'Import-Module -ArgumentList (...)' could be replaced with:"
        if ($ParamName -ne $GlobalName) {
            Write-Verbose "`t> `$$ParamName = `"$GlobalName`""
            $propName = "`$$ParamName"
        }
        Write-Verbose "`t> `$$props = `@{"
        Write-Verbose "`t>`t `"$propName`" = `$true;"
        Write-Verbose "`t>`t (...) }"
        Write-Verbose "`t> Import-Module"

        return $true
    }

    return $global:PoshGit_InitProps[$GlobalName]
}

__logEvent "setting ``param()`` from `$global:PoshGit_InitProps"
$ForcePoshGitPrompt = Get-ParamOverrideOf `
    $ForcePoshGitPrompt "ForcePoshGitPrompt"

$UseLegacyTabExpansion = Get-ParamOverrideOf `
    $UseLegacyTabExpansion "UseLegacyTabExpansion"

$EnableProxyFunctionExpansion = Get-ParamOverrideOf `
    $EnableProxyFunctionExpansion "EnableProxyFunctionExpansion" `
    -GlobalName "UseFunctionCompletion"

__logScopePop
