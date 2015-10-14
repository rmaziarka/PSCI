<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

Import-Module -Name "$PSScriptRoot\..\..\..\..\PSCI.psd1" -Force

Describe -Tag "PSCI.unit" "Resolve-Tokens" {

    InModuleScope PSCI.deploy {

        Mock Write-Log { 
            Write-Host $Message
            if ($Critical) {
                throw $Message
            }
        }

        Context "when used with server" {
            $Global:Environments = @{}

            Environment Default {
                Tokens WebConfig @{
                    SessionTimeout = '30'
                    NLogLevels = 'Error,Fatal'
                    DatabaseName = "Test"
                }
            }

            Environment Live {
                Tokens WebConfig @{
                    SessionTimeout = '40'
                    NLogLevels = 'Fatal'
                }

                Server 's01' {
                    Tokens WebConfig @{
                        SessionTimeout = '35'
                    }
                }
            }

            Environment Live_Perf {
                Tokens WebConfig @{
                    SessionTimeout = '55'
                    NLogLevels = 'Info'
                }

                Server 's01' {
                    Tokens WebConfig @{
                        SessionTimeout = '70'
                    }
                }
            }

            It "Resolve-Tokens: should properly resolve tokens for Default environment" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 3

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 30
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Error,Fatal'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Test'
            }

            It "Resolve-Tokens: should properly resolve tokens for Live environment and node 's02'" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live -Node 's02'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 3

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 40
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Fatal'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Test'
            }

            It "Resolve-Tokens: should properly resolve tokens for Live environment and node 's01'" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 3

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 35
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Fatal'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Test'
            }

            It "Resolve-Tokens: should properly resolve tokens for Live_Perf environment and node 's01'" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live_Perf -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 3

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 70
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Info'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Test'
            }

            It "Resolve-Tokens: should properly resolve tokens for Live_Perf environment and node 's02'" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live_Perf -Node 's02'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 3

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 55
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Info'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Test'
            }
        }

        Context "with inheritance" {
            $Global:Environments = @{}

            Environment Live_Perf -BasedOn Live {
                Tokens WebConfig @{
                    NLogLevels = 'Info'
                    LogDir = 'C:\Logs'
                }
            }

            Environment Default {
                Tokens WebConfig @{
                    SessionTimeout = '30'
                    NLogLevels = 'Warning,Error,Fatal'
                    DatabaseName = 'Test'
                }
            }

            Environment Live_Perf2 -BasedOn Live_Perf {
                Tokens WebConfig @{
                    SessionTimeout = '100'
                }
            }

            Environment Live {
                Tokens WebConfig @{
                    NLogLevels = 'Fatal'
                    DatabaseName = 'Live'
                    Impersonate = 'true'
                }
            }

            It "Resolve-Tokens: should properly resolve tokens for children environment" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live_Perf -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 5

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 30
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Info'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Live'
                $resolvedTokens.WebConfig.Impersonate | Should Be 'true'
                $resolvedTokens.WebConfig.LogDir | Should Be 'C:\Logs'
            }

            It "Resolve-Tokens: should properly resolve tokens for granchildren environment" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Live_Perf2 -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 5

                $resolvedTokens.WebConfig.SessionTimeout | Should Be 100
                $resolvedTokens.WebConfig.NLogLevels | Should Be 'Info'
                $resolvedTokens.WebConfig.DatabaseName | Should Be 'Live'
                $resolvedTokens.WebConfig.Impersonate | Should Be 'true'
                $resolvedTokens.WebConfig.LogDir | Should Be 'C:\Logs'
            }
        }
    
        Context "when used with types other than string" {
            $Global:Environments = @{}

            Environment Default {
                Tokens WebConfig @{
                    Credentials = ConvertTo-PSCredential -User "Test" -Password "Test"
                    Timeout = 60
                }
            }

            It "Resolve-Tokens: should properly resolve tokens" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 2

                $resolvedTokens.WebConfig.Credentials | Should Not Be $null
                $resolvedTokens.WebConfig.Credentials.GetType() | Should Be PSCredential
                $resolvedTokens.WebConfig.Timeout | Should Be 60
                $resolvedTokens.WebConfig.Timeout.GetType() | Should Be int
            }
        }

        Context "with ciclomatic inheritance" {
            $Global:Environments = @{}
    
            Environment Default {
                Tokens WebConfig @{
                    SessionTimeout = '30'
                }
            }

            Environment E1 -BasedOn E3 {
                Tokens WebConfig @{
                    SessionTimeout = '40'
                }
            }

            Environment E2 -BasedOn E1 {
                Tokens WebConfig @{
                    SessionTimeout = '40'
                }
            }

            Environment E3 -BasedOn E2 {
                Tokens WebConfig @{
                    SessionTimeout = '40'
                }
            }

            It "Resolve-Tokens: should properly throw exception" {
                Try {
                    Resolve-Tokens -AllEnvironments $Global:Environments -Environment E3 -Node 's01' | Should Throw
                }
                Catch {
                }
            }
        }
    
        Context "with tokens substitution" {
            $Global:Environments = @{}

            Environment Default {

                Tokens Common @{
                    ConnectionString = 'Server=${Node};Database=Hub;Integrated Security=True;MultipleActiveResultSets=True'
                }

                Tokens WebDeployConfig @{
                    'Some-Web.config Connection String' = '${ConnectionString}'
                    'Second-ConnectionString' = '${Common.ConnectionString}'
                    'TwoStrings' = '${ConnectionString},${Common.ConnectionString}'
                }
            }

            It "Resolve-Tokens: should properly substitute tokens" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

                $resolvedTokens.Common | Should Not Be $null
                $resolvedTokens.Common.ConnectionString | Should Not Be $null
                $resolvedTokens.Common.ConnectionString.StartsWith('Server=s01;') | Should Be $true

                $resolvedTokens.WebDeployConfig | Should Not Be $null
                $resolvedTokens.WebDeployConfig['Some-Web.config Connection String'] | Should Not Be $null
                $resolvedTokens.WebDeployConfig['Some-Web.config Connection String'] | Should Be $resolvedTokens.Common.ConnectionString
                $resolvedTokens.WebDeployConfig['Second-ConnectionString'] | Should Not Be $null
                $resolvedTokens.WebDeployConfig['Second-ConnectionString'] | Should Be $resolvedTokens.Common.ConnectionString
                $resolvedTokens.WebDeployConfig['TwoStrings'] | Should Not Be $null
                $resolvedTokens.WebDeployConfig['TwoStrings'] | Should Be ('{0},{1}' -f $resolvedTokens.Common.ConnectionString, $resolvedTokens.Common.ConnectionString)
            }

            Environment Default {
                Tokens WebDeployConfig @{
                    'Second-ConnectionString' = '${Common.ConnectionStringInvalid}'
                }
            }

            It "Resolve-Tokens: should fail if token (category.name) is invalid" {
                { Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' } | Should Throw
            }

            Environment Default {
                Tokens WebDeployConfig @{
                    'Second-ConnectionString' = '${ConnectionStringInvalid}'
                }
            }

            It "Resolve-Tokens: should fail if token (name) is invalid" {
                { Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' } | Should Throw
            }

        }

        Context "with scriptblock as tokens value" {
            $Global:Environments = @{}

            Environment Default {

                Tokens Common @{
                    Domain = 'Domain'
                    User = 'User'
                    Password = 'Pass'
                    Credentials = { ConvertTo-PSCredential -User "$($Tokens.Common.Domain)\$($Tokens.Common.User)" -Password $Tokens.Common.Password }
                    NodeTest = { $Node }
                    EnvironmentTest = { $Environment }
                }
            }

            It "Resolve-Tokens: should properly evaluate scriptblock" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

                $resolvedTokens.Common | Should Not Be $null
                $resolvedTokens.Common.Credentials | Should Not Be $null
                $resolvedTokens.Common.Credentials.GetType().FullName | Should Be 'System.Management.Automation.PSCredential'
                $resolvedTokens.Common.Credentials.UserName | Should Be 'Domain\User'
                $resolvedTokens.Common.Credentials.GetNetworkCredential().Password | Should Be 'Pass'

                $resolvedTokens.All | Should Not Be $null
                $resolvedTokens.All.Credentials | Should Not Be $null
                $resolvedTokens.All.Credentials.GetType().FullName | Should Be 'System.Management.Automation.PSCredential'
                $resolvedTokens.All.Credentials.UserName | Should Be 'Domain\User'
                $resolvedTokens.All.Credentials.GetNetworkCredential().Password | Should Be 'Pass'

                $resolvedTokens.Common.NodeTest | Should Be 's01'
                $resolvedTokens.Common.EnvironmentTest | Should Be 'Default'

                $resolvedTokens.All.NodeTest | Should Be 's01'
                $resolvedTokens.All.EnvironmentTest | Should Be 'Default'
            }
        }

        <# TODO: this is not implemented yet
        Context "with 'double-hop' scriptblock as tokens value" {
            $Global:Environments = @{}

            Environment Default {

                Tokens Common @{
                    Domain = 'Domain'
                    User = 'User'
                    Password = 'Pass'

                    DomainFirstHop = { $Tokens.Common.Domain }
                    UserFirstHop = { $Tokens.Common.User }
                    PasswordFirstHop = { $Tokens.Common.Password }

                    CredentialsSecondHop = { ConvertTo-PSCredential -User "$($Tokens.Common.DomainFirstHop)\$($Tokens.Common.UserFirstHop)" -Password $Tokens.Common.PasswordFirstHop }

                }
            }

            It "Resolve-Tokens: should properly evaluate scriptblock" {
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

                $resolvedTokens.Common | Should Not Be $null
                $resolvedTokens.Common.CredentialsSecondHop | Should Not Be $null
                $resolvedTokens.Common.CredentialsSecondHop.GetType().FullName | Should Be 'System.Management.Automation.PSCredential'
                $resolvedTokens.Common.CredentialsSecondHop.UserName | Should Be 'Domain\User'
                $resolvedTokens.Common.CredentialsSecondHop.GetNetworkCredential().Password | Should Be 'Pass'

                $resolvedTokens.All.CredentialsSecondHop | Should Not Be $null
                $resolvedTokens.All.CredentialsSecondHop.GetType().FullName | Should Be 'System.Management.Automation.PSCredential'
                $resolvedTokens.All.CredentialsSecondHop.UserName | Should Be 'Domain\User'
                $resolvedTokens.All.CredentialsSecondHop.GetNetworkCredential().Password | Should Be 'Pass'
            }
        }
        #>

        Context "when used with TokensOverride" {
            $Global:Environments = @{}

            Environment Default {
                Tokens WebConfig @{
                    Credentials = ''
                    Timeout = 60
                }
            }

            It "Resolve-Tokens: should properly resolve flat tokens" {
                $tokensOverride = @{ 'Credentials' = ConvertTo-PSCredential -User "Test" -Password "Test" }
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' -TokensOverride $tokensOverride

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 2

                $resolvedTokens.WebConfig.Credentials | Should Not Be $null
                $resolvedTokens.WebConfig.Credentials.GetType() | Should Be PSCredential
                $resolvedTokens.WebConfig.Timeout | Should Be 60
                $resolvedTokens.WebConfig.Timeout.GetType() | Should Be int
            }

            It "Resolve-Tokens: should properly resolve hierarchical tokens" {
                $tokensOverride = @{ 'WebConfig.Credentials' = ConvertTo-PSCredential -User "Test" -Password "Test" }
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' -TokensOverride $tokensOverride

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 2

                $resolvedTokens.WebConfig.Credentials | Should Not Be $null
                $resolvedTokens.WebConfig.Credentials.GetType() | Should Be PSCredential
                $resolvedTokens.WebConfig.Timeout | Should Be 60
                $resolvedTokens.WebConfig.Timeout.GetType() | Should Be int
            }

            It "Resolve-Tokens: should resolve tokens as bool for $true / $false" {
                $tokensOverride = @{ 'Credentials' = '$true'; Timeout = '$false' }
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' -TokensOverride $tokensOverride

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 2

                $resolvedTokens.WebConfig.Credentials | Should Be $true
                $resolvedTokens.WebConfig.Credentials.GetType() | Should Be bool
                $resolvedTokens.WebConfig.Timeout | Should Be $false
                $resolvedTokens.WebConfig.Timeout.GetType() | Should Be bool
            }

            It "Resolve-Tokens: should resolve tokens as string for true / false" {
                $tokensOverride = @{ 'Credentials' = 'true'; Timeout = 'false' }
                $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01' -TokensOverride $tokensOverride

                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.WebConfig | Should Not Be $null
                $resolvedTokens.WebConfig.Count | Should Be 2

                $resolvedTokens.WebConfig.Credentials | Should Be 'true'
                $resolvedTokens.WebConfig.Credentials.GetType() | Should Be string
                $resolvedTokens.WebConfig.Timeout | Should Be 'false'
                $resolvedTokens.WebConfig.Timeout.GetType() | Should Be string
            }
        }

        Context "when used in more complex scenarios" {
            $Global:Environments = @{}

            Environment Default {
                Tokens Credentials @{
                    User = 'user1' 
                    User2 = '${User}'
                    # this is why we need 3 passes of Resolve-Tokens - tokens, scripts, tokens again
                    PSCredential = { ConvertTo-PSCredential -User $Tokens.Credentials.User2 -Password 'test' } 
                    User3 = { $Tokens.Credentials.User2 }
                    User4 = '${User3}'
                }
            }

            $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

            It "Should properly resolve tokens" {
                $resolvedTokens.Count | Should Be 3
                $resolvedTokens.Credentials.User | should Be 'user1'
                $resolvedTokens.Credentials.User2 | should Be 'user1'
                $resolvedTokens.Credentials.User3 | should Be 'user1'
                $resolvedTokens.Credentials.User4 | should Be 'user1'
                $resolvedTokens.Credentials.PSCredential.UserName | should Be 'user1'
            }
        }

        Context "when used with array" {
            $Global:Environments = @{}

            Environment Default {
                Tokens DestinationNodes @{
                    ExternalNodeValue = 'localhost:e', 'localhost:e2'
                }

                Tokens Node @{
                    SelectedNode = 'localhost:i', 'localhost:i2'
                    ExternalNode = { $Tokens.DestinationNodes.ExternalNodeValue }
                }
            }

            $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

            It "Should properly resolve tokens" {
                $resolvedTokens.Count | Should Be 4
                $resolvedTokens.Node.SelectedNode.Count | should Be 2
                $resolvedTokens.Node.SelectedNode | should Be @('localhost:i', 'localhost:i2')
                $resolvedTokens.Node.ExternalNode.Count | should Be 2
                $resolvedTokens.Node.ExternalNode | should Be @('localhost:e', 'localhost:e2')
            }
        }

        Context "when used with hashtables" {
            $Global:Environments = @{}

            Environment Default {
                Tokens DestinationNodes @{
                    ExternalNodeValue = { 'localhost:e' }
                    NodesMap = @{ 
                        'localhost'  = @{ 
                            InternalNode = { return 'localhost:i' }
                            ExternalNode = '${ExternalNodeValue}'
                            #Nested = @{ NestedNode = { return 'nested' } } 
                        }
                        ExternalNodeScriptBlock = { $Tokens.DestinationNodes.ExternalNodeValue }
                        ExternalNodeStringRef = '${ExternalNodeValue}'
                    }
                }

                Tokens Node @{
                    SelectedNode = 'localhost'
                    InternalNode = { $Tokens.DestinationNodes.NodesMap[$Tokens.Node.SelectedNode].InternalNode }
                    ExternalNode = { $Tokens.DestinationNodes.NodesMap[$Tokens.Node.SelectedNode].ExternalNode }
                }
            }

            $resolvedTokens = Resolve-Tokens -AllEnvironments $Global:Environments -Environment Default -Node 's01'

            It "Should properly resolve tokens" {
                $resolvedTokens.Count | Should Be 4
                $resolvedTokens.Node.InternalNode | should Be 'localhost:i'
                $resolvedTokens.Node.ExternalNode | should Be 'localhost:e'
                $resolvedTokens.DestinationNodes.NodesMap.ExternalNodeScriptBlock | should Be 'localhost:e'
                $resolvedTokens.DestinationNodes.NodesMap.ExternalNodeStringRef | should Be 'localhost:e'
                #$resolvedTokens.DestinationNodes.NodesMap.localhost.InternalNode | should Be 'localhost:i'
                #$resolvedTokens.DestinationNodes.NodesMap.localhost.ExternalNode | should Be 'localhost:e'
                #$resolvedTokens.DestinationNodes.NodesMap.localhost.Nested.NestedNode | should Be 'nested'
            }
        }
    }
}

