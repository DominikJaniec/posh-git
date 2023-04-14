BeforeAll {
    . $PSScriptRoot\Shared.ps1
}

Describe "PoshGit_InitProps" {
    It "is defined globally" {
        $global:PoshGit_InitProps `
        | Should -Not -BeNullOrEmpty
    }

    It "has only expected keys" {
        $expectedKeys = `
            , "ForcePoshGitPrompt" `
            , "UseLegacyTabExpansion" `
            , "UseFunctionCompletion" `
            , "ShowCompletionErrors" `
        | Sort-Object

        $global:PoshGit_InitProps.Keys `
        | Sort-Object `
        | Should -Be $expectedKeys
    }
}

Describe "Get-ParamOverrideOf" {
    InModuleScope "posh-git" {
        BeforeEach {
            $globalKey = "an-example"
            $globalValue = New-Guid

            $global:PoshGit_InitProps[$globalKey] = $globalValue
        }

        Context "When ParamValue is not True, but is '<_>'" `
            -ForEach @($false, "some-magic-value", 42) {

            It "extracts value form global PoshGit_InitProps" {
                Get-ParamOverrideOf -ParamValue $_ `
                    -ParamName $globalKey `
                | Should -Be $globalValue
            }

            It "can use GlobalName argument insted of ParamName" {
                Get-ParamOverrideOf -ParamValue $_ `
                    -ParamName "ignored" `
                    -GlobalName $globalKey `
                | Should -Be $globalValue
            }
        }

        Context "When ParamValue is exactly True" {
            It "returns always True and ignores PoshGit_InitProps" {
                Get-ParamOverrideOf -ParamValue $true `
                    -ParamName $globalKey `
                | Should -Be $true

                Get-ParamOverrideOf -ParamValue $true `
                    -ParamName "ignored" `
                    -GlobalName $globalKey `
                | Should -Be $true

                Get-ParamOverrideOf -ParamValue $true `
                    -ParamName "neglectable" `
                    -GlobalName "negligible" `
                | Should -Be $true
            }

            Context "Verbose tutorial of alternative to ArgumentList" {
                BeforeEach {
                    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssigments', '')]
                    $verboseLog = [System.Text.StringBuilder]::new()

                    Mock -CommandName Write-Verbose -MockWith {
                        $line = "$($PesterBoundParameters.Message)"
                        $verboseLog.AppendLine($line) `
                        | Out-Null
                    }
                }

                It "shows a given ParamName as PoshGit_InitProps key" {
                    Get-ParamOverrideOf -ParamValue $true `
                        -ParamName "ModuleArgumentName" `
                    | Should -Be $true

                    Should -Invoke Write-Verbose
                    $verboseLog | Should -Be @"
The 'Import-Module -ArgumentList (...)' could be replaced with:
`t> `$global:PoshGit_InitProps = @{
`t>`t "ModuleArgumentName" = `$true;
`t>`t (...) }
`t> Import-Module

"@
                }

                It "uses GlobalName argument insted of ParamName" {
                    Get-ParamOverrideOf -ParamValue $true `
                        -ParamName "OldArgumentName" `
                        -GlobalName "TheNewOne" `
                    | Should -Be $true

                    Should -Invoke Write-Verbose
                    $verboseLog | Should -Be @"
The 'Import-Module -ArgumentList (...)' could be replaced with:
`t> `$OldArgumentName = "TheNewOne"
`t> `$global:PoshGit_InitProps = @{
`t>`t "`$OldArgumentName" = `$true;
`t>`t (...) }
`t> Import-Module

"@
                }
            }
        }
    }
}
