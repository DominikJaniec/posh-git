param ($DefaultProps)

if (Test-Path variable:global:PoshGit_InitProps) {
    foreach ($key in $DefaultProps.Keys) {
        if (-not $global:PoshGit_InitProps.ContainsKey($key)) {
            $global:PoshGit_InitProps[$key] = $DefaultProps[$key]
        }
    }
}
else {
    $global:PoshGit_InitProps = $DefaultProps.Clone()
}

function Get-ParamOverrideOf ($ParamValue, $ParamName, $GlobalName = $null) {
    $GlobalName ??= $ParamName

    if ($ParamValue -eq $true) {
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

$ForcePoshGitPrompt = Get-ParamOverrideOf `
    $ForcePoshGitPrompt "ForcePoshGitPrompt"

$UseLegacyTabExpansion = Get-ParamOverrideOf `
    $UseLegacyTabExpansion "UseLegacyTabExpansion"

$EnableProxyFunctionExpansion = Get-ParamOverrideOf `
    $EnableProxyFunctionExpansion "EnableProxyFunctionExpansion" `
    -GlobalName "UseFunctionCompletion"
