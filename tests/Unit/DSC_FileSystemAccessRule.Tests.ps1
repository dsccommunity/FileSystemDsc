$script:dscModuleName = 'FileSystemDsc'
$script:dscResourceName = 'DSC_FileSystemAccessRule'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        Set-StrictMode -Version 1.0

        $mockIdentity = 'NT AUTHORITY\NETWORK SERVICE'

        <#
            The filesystem doesn't return a string array for ACLs, it returns a
            bit-flagged [System.Security.AccessControl.FileSystemRights].
        #>
        $mockFileSystemRights = [System.Security.AccessControl.FileSystemRights] @('ReadData', 'WriteAttributes')

        Describe 'DSC_FileSystemAccessRule\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $mockPath = $TestDrive.FullName

                $mockGetTargetResourceParameters = @{
                    Path     = $mockPath
                    Identity = $mockIdentity
                    Verbose  = $true
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    Context 'When the node does not belong to a cluster' {
                        BeforeAll {
                            Mock -CommandName Write-Warning
                            Mock -CommandName Get-Acl

                            Mock -CommandName Test-Path -MockWith {
                                return $false
                            }

                            Mock -CommandName Get-CimInstance
                        }

                        It 'Should not throw and output the correct warning message' {
                            { $script:result = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-Acl -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                                $ClassName -eq 'MSCluster_Cluster'
                            } -Exactly -Times 1 -Scope It
                        }

                        It 'Should return the state as absent' {
                            $script:result.Ensure | Should -Be 'Absent'
                        }

                        It 'Should return the same values as passed as parameters' {
                            $script:result.Path | Should -Be $mockPath
                            $script:result.Identity | Should -Be $mockIdentity
                        }

                        It 'Should return the correct values for the rest of the properties' {
                            $script:result.Rights | Should -BeNullOrEmpty
                            $script:result.IsActiveNode | Should -BeTrue
                        }
                    }

                    Context 'When no cluster disk partition is found that uses the path' {
                        BeforeAll {
                            Mock -CommandName Write-Warning
                            Mock -CommandName Get-Acl
                            Mock -CommandName Get-CimAssociatedInstance
                            Mock -CommandName Test-Path -MockWith {
                                return $false
                            }

                            Mock -CommandName Get-CimInstance -MockWith {
                                return @(
                                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_Resource', 'root/MSCluster' |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MOCKCLUSTER' -PassThru -Force
                                )
                            } -ParameterFilter {
                                $ClassName -eq 'MSCluster_Cluster'
                            }

                            Mock -CommandName Get-CimInstance -MockWith {
                                return @(
                                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_ClusterDiskPartition', 'root/MSCluster' |
                                        Add-Member -MemberType 'NoteProperty' -Name 'MountPoints' -Value @('K:') -PassThru -Force
                                )
                            } -ParameterFilter {
                                $ClassName -eq 'MSCluster_ClusterDiskPartition'
                            }
                        }

                        It 'Should not throw and output the correct warning message' {
                            { $script:result = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-Acl -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                                $ClassName -eq 'MSCluster_Cluster'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                                $ClassName -eq 'MSCluster_ClusterDiskPartition'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -Exactly -Times 0 -Scope It

                            Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                                $Message -eq ($script:localizedData.PathDoesNotExist -f $mockPath)
                            } -Exactly -Times 1 -Scope It
                        }

                        It 'Should return the state as absent' {
                            $script:result.Ensure | Should -Be 'Absent'
                        }

                        It 'Should return the same values as passed as parameters' {
                            $script:result.Path | Should -Be $mockPath
                            $script:result.Identity | Should -Be $mockIdentity
                        }

                        It 'Should return the correct values for the rest of the properties' {
                            $script:result.Rights | Should -BeNullOrEmpty
                            $script:result.IsActiveNode | Should -BeTrue
                        }
                    }
                }

                Context 'When the current node is not a possible cluster resource owner' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Get-Acl
                        Mock -CommandName Test-Path -MockWith {
                            return $false
                        }

                        $mockMSCluster_Cluster = @(
                            New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_Resource', 'root/MSCluster' |
                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MOCKCLUSTER' -PassThru -Force
                        )

                        Mock -CommandName Get-CimInstance -MockWith {
                            return $mockMSCluster_Cluster
                        } -ParameterFilter {
                            $ClassName -eq 'MSCluster_Cluster'
                        }

                        Mock -CommandName Get-CimInstance -MockWith {
                            return @(
                                New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_ClusterDiskPartition', 'root/MSCluster' |
                                    Add-Member -MemberType 'NoteProperty' -Name 'MountPoints' -Value @(
                                        (Split-Path -Path $mockPath -Qualifier)
                                    ) -PassThru -Force
                            )
                        } -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterDiskPartition'
                        }

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {
                            return $mockMSCluster_Cluster
                        } -ParameterFilter {
                            $ResultClassName -eq 'MSCluster_Resource'
                        }

                        Mock -CommandName Get-CimAssociatedInstance -MockWith {
                            return @(
                                'OtherOwner' | ForEach-Object -Process {
                                    $node = $_

                                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_ResourceToPossibleOwner', 'root/MSCluster' |
                                        Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $node -PassThru -Force
                                }
                            )
                        } -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        }
                    }

                    It 'Should not throw and output the correct warning message' {
                        { $script:result = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-Acl -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'MSCluster_Cluster'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                            $ClassName -eq 'MSCluster_ClusterDiskPartition'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $ResultClassName -eq 'MSCluster_Resource'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                            $Association -eq 'MSCluster_ResourceToPossibleOwner'
                        } -Exactly -Times 1 -Scope It

                        Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                            $Message -eq ($script:localizedData.PathDoesNotExist -f $mockPath)
                        } -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the state as absent' {
                        $script:result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $script:result.Path | Should -Be $mockPath
                        $script:result.Identity | Should -Be $mockIdentity
                    }

                    It 'Should return the correct values for the rest of the properties' {
                        $script:result.Rights | Should -BeNullOrEmpty
                        $script:result.IsActiveNode | Should -BeTrue
                    }
                }

                Context 'When the configuration is present' {
                    Context 'When the path exist' {
                        BeforeAll {
                            Mock -CommandName Get-Acl -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Access' -Value @(
                                        New-Object -TypeName PSObject |
                                            Add-Member -MemberType 'NoteProperty' -Name 'IdentityReference' -Value $mockIdentity -PassThru |
                                                Add-Member -MemberType 'NoteProperty' -Name 'FileSystemRights' -Value $mockFileSystemRights -PassThru -Force
                                    ) -PassThru |
                                        Add-Member -MemberType 'ScriptMethod' -Name "SetAccessRule" -Value {
                                            $script:SetAccessRuleMethodCallCount += 1
                                        } -PassThru |
                                            Add-Member -MemberType 'ScriptMethod' -Name "RemoveAccessRule" -Value {
                                                $script:RemoveAccessRuleMethodCallCount += 1
                                            } -PassThru -Force
                            }
                        }

                        It 'Should get the access rules without throwing' {
                            { $script:result = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-Acl -Exactly -Times 1 -Scope It
                        }

                        It 'Should return the state as present' {
                            $script:result.Ensure | Should -Be 'Present'
                        }

                        It 'Should return the same values as passed as parameters' {
                            $script:result.Path | Should -Be $mockPath
                            $script:result.Identity | Should -Be $mockIdentity
                        }

                        It 'Should return the correct values for the rest of the properties' {
                            $script:result.Rights | Should -HaveCount 2
                            $script:result.Rights | Should -Contain 'ReadData'
                            $script:result.Rights | Should -Contain 'WriteAttributes'
                            $script:result.IsActiveNode | Should -BeTrue
                        }
                    }

                    Context 'When path is not found on the node, but the path is found in a cluster disk partition and the current node is a possible cluster resource owner' {
                        BeforeAll {
                            Mock -CommandName Write-Warning
                            Mock -CommandName Get-Acl
                            Mock -CommandName Test-Path -MockWith {
                                return $false
                            }

                            $mockMSCluster_Cluster = @(
                                New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_Resource', 'root/MSCluster' |
                                    Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'MOCKCLUSTER' -PassThru -Force
                            )

                            Mock -CommandName Get-CimInstance -MockWith {
                                return $mockMSCluster_Cluster
                            } -ParameterFilter {
                                $ClassName -eq 'MSCluster_Cluster'
                            }

                            Mock -CommandName Get-CimInstance -MockWith {
                                return @(
                                    New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_ClusterDiskPartition', 'root/MSCluster' |
                                        Add-Member -MemberType 'NoteProperty' -Name 'MountPoints' -Value @(
                                            (Split-Path -Path $mockPath -Qualifier)
                                        ) -PassThru -Force
                                )
                            } -ParameterFilter {
                                $ClassName -eq 'MSCluster_ClusterDiskPartition'
                            }

                            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                                return $mockMSCluster_Cluster
                            } -ParameterFilter {
                                $ResultClassName -eq 'MSCluster_Resource'
                            }

                            Mock -CommandName Get-CimAssociatedInstance -MockWith {
                                return @(
                                    @(
                                        $env:COMPUTERNAME,
                                        'Node1',
                                        'Node2'
                                    ) |
                                        ForEach-Object -Process {
                                            $node = $_

                                            New-Object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -ArgumentList 'MSCluster_ResourceToPossibleOwner', 'root/MSCluster' |
                                                Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $node -PassThru -Force
                                        }
                                )
                            } -ParameterFilter {
                                $Association -eq 'MSCluster_ResourceToPossibleOwner'
                            }
                        }

                        It 'Should not throw and should not output a warning message' {
                            { $script:result = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-Acl -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Test-Path -Times 1 -Exactly -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                                $ClassName -eq 'MSCluster_Cluster'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter {
                                $ClassName -eq 'MSCluster_ClusterDiskPartition'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                                $ResultClassName -eq 'MSCluster_Resource'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Get-CimAssociatedInstance -ParameterFilter {
                                $Association -eq 'MSCluster_ResourceToPossibleOwner'
                            } -Exactly -Times 1 -Scope It

                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope It
                        }

                        It 'Should return the state as present' {
                            $script:result.Ensure | Should -Be 'Present'
                        }

                        It 'Should return the same values as passed as parameters' {
                            $script:result.Path | Should -Be $mockPath
                            $script:result.Identity | Should -Be $mockIdentity
                        }

                        It 'Should return the correct values for the rest of the properties' {
                            $script:result.Rights | Should -BeNullOrEmpty
                            $script:result.IsActiveNode | Should -BeFalse
                        }
                    }
                }
            }
        }

        Describe 'DSC_FileSystemAccessRule\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $mockPath = $TestDrive

                $mockDefaultParameters = @{
                    Path     = $mockPath
                    Identity = $mockIdentity
                    Verbose  = $true
                }
            }

            Context 'When the node is part of a cluster and is not the active node' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure       = 'Absent'
                            Path         = $mockPath
                            Identity     = $mockIdentity
                            Rights       = [System.String[]] @()
                            IsActiveNode = $false
                        }
                    }

                    $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                    $mockTestTargetResourceParameters['ProcessOnlyOnActiveNode'] = $true
                }

                It 'Should return the state as $true' {
                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the configuration is absent' {
                    Context 'When the identity have no rights in the current state' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @()
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                            $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                        }

                        It 'Should return the state as $true' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                        }
                    }

                    Context 'When the identity are not allowed to have certain rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @('ReadData')
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                            $mockTestTargetResourceParameters['Rights'] = @('Modify')
                        }

                        It 'Should return the state as $true' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                        }
                    }
                }

                Context 'When the configuration is present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure       = 'Present'
                                Path         = $mockPath
                                Identity     = $mockIdentity
                                Rights       = [System.String[]] @('ReadData')
                                IsActiveNode = $true
                            }
                        }

                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                    }

                    It 'Should return the state as $true' {
                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure       = 'Present'
                                Path         = $mockPath
                                Identity     = $mockIdentity
                                Rights       = [System.String[]] @('ReadData')
                                IsActiveNode = $true
                            }
                        }

                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                    }

                    It 'Should return the state as $false' {
                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                    }

                    Context 'When not passing the parameter Rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @('ReadData')
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        }

                        It 'Should return the state as $false' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                        }
                    }

                    Context 'When the identity are not allowed to have certain rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @('Modify')
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                            $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                        }

                        It 'Should return the state as $false' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                        }
                    }
                }

                Context 'When the configuration should be present' {
                    Context 'When not passing the parameter Rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @('ReadData')
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Present'
                        }

                        It 'Should throw the correct error message' {
                            $mockErrorMessage = $script:localizedData.NoRightsWereSpecified -f $mockIdentity, $mockPath
                            { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw $mockErrorMessage
                        }
                    }

                    Context 'When the identity does not have any previous rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Absent'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @()
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                        }

                        It 'Should return the state as $false' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                        }
                    }

                    Context 'When the identity is missing rights' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    Ensure       = 'Present'
                                    Path         = $mockPath
                                    Identity     = $mockIdentity
                                    Rights       = [System.String[]] @('ReadData')
                                    IsActiveNode = $true
                                }
                            }

                            $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockTestTargetResourceParameters['Ensure'] = 'Present'
                            $mockTestTargetResourceParameters['Rights'] = @('Modify')
                        }

                        It 'Should return the state as $false' {
                            Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                        }
                    }
                }
            }
        }

        Describe 'DSC_FileSystemAccessRule\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $mockPath = $TestDrive

                $mockDefaultParameters = @{
                    Path     = $mockPath
                    Identity = $mockIdentity
                    Verbose  = $true
                }

                $mockGetAcl = {
                    return New-Object -TypeName PSObject |
                        Add-Member -MemberType 'NoteProperty' -Name 'Access' -Value @(
                            (
                                New-Object -TypeName PSObject |
                                    Add-Member -MemberType 'NoteProperty' -Name 'IdentityReference' -Value $mockIdentity -PassThru |
                                        Add-Member -MemberType 'NoteProperty' -Name 'FileSystemRights' -Value $mockFileSystemRights -PassThru -Force
                            ),
                            (
                                New-Object -TypeName PSObject |
                                    Add-Member -MemberType 'NoteProperty' -Name 'IdentityReference' -Value 'DOMAIN\Users' -PassThru |
                                        Add-Member -MemberType 'NoteProperty' -Name 'FileSystemRights' -Value 'Modify' -PassThru -Force
                            )
                        ) -PassThru |
                            Add-Member -MemberType ScriptMethod -Name "SetAccessRule" -Value {
                                $script:SetAccessRuleMethodCallCount += 1
                            } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name "PurgeAccessRules" -Value {
                                    $script:PurgeAccessRulesMethodCallCount += 1
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {
                                        $script:RemoveAccessRuleMethodCallCount += 1
                                    } -PassThru -Force
                }

                Mock -CommandName Get-Acl -MockWith $mockGetAcl
                Mock -CommandName Set-Acl
            }

            BeforeEach {
                $script:SetAccessRuleMethodCallCount = 0
                $script:PurgeAccessRulesMethodCallCount = 0
                $script:RemoveAccessRuleMethodCallCount = 0
            }

            Context 'When the specified path is missing' {
                BeforeAll {
                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }

                    $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockSetTargetResourceParameters['Rights'] = @('ReadData')
                }

                It 'Should throw the correct error' {
                    $mockErrorMessage = $script:localizedData.PathDoesNotExist -f $mockPath

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When not passing the parameter Rights' {
                BeforeAll {
                    $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                }

                It 'Should throw the correct error' {
                    $mockErrorMessage = $script:localizedData.NoRightsWereSpecified -f $mockIdentity, $mockPath

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the configuration should be absent' {
                    Context 'When the specific permissions should be absent' {
                        BeforeAll {
                            $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                            $mockSetTargetResourceParameters['Rights'] = @('ReadData','Delete')
                        }

                        It 'Should call the correct methods and mocks to remove the permissions' {
                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Get-Acl -Exactly -Times 1 -Scope It

                            $script:SetAccessRuleMethodCallCount | Should -Be 0
                            $script:PurgeAccessRulesMethodCallCount | Should -Be 0
                            $script:RemoveAccessRuleMethodCallCount | Should -Be 2

                            Assert-MockCalled -CommandName Set-Acl -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When all the permissions for the identity should be purged' {
                        Context 'When the parameter Rights is set to an empty hashtable' {
                            BeforeAll {
                                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                                $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                                $mockSetTargetResourceParameters['Rights'] = @()
                            }

                            It 'Should call the correct methods and mocks to remove the permissions' {
                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Assert-MockCalled -CommandName Get-Acl -Exactly -Times 1 -Scope It

                                $script:SetAccessRuleMethodCallCount | Should -Be 0
                                $script:PurgeAccessRulesMethodCallCount | Should -Be 1
                                $script:RemoveAccessRuleMethodCallCount | Should -Be 0

                                Assert-MockCalled -CommandName Set-Acl -Exactly -Times 1 -Scope It
                            }
                        }

                        Context 'When the parameter Rights is not specified' {
                            BeforeAll {
                                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                                $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                            }

                            It 'Should call the correct methods and mocks to remove the permissions' {
                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Assert-MockCalled -CommandName Get-Acl -Exactly -Times 1 -Scope It

                                $script:SetAccessRuleMethodCallCount | Should -Be 0
                                $script:PurgeAccessRulesMethodCallCount | Should -Be 1
                                $script:RemoveAccessRuleMethodCallCount | Should -Be 0

                                Assert-MockCalled -CommandName Set-Acl -Exactly -Times 1 -Scope It
                            }
                        }
                    }
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
                        $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockSetTargetResourceParameters['Rights'] = @('Modify')
                    }

                    It 'Should call the correct methods and mocks to set the permissions' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Get-Acl -Exactly -Times 1 -Scope It

                        $script:SetAccessRuleMethodCallCount | Should -Be 1
                        $script:PurgeAccessRulesMethodCallCount | Should -Be 0
                        $script:RemoveAccessRuleMethodCallCount | Should -Be 0

                        Assert-MockCalled -CommandName Set-Acl -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the access rules fails to be set' {
                    BeforeAll {
                        Mock -CommandName Set-Acl -MockWith {
                            throw
                        }

                        $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockSetTargetResourceParameters['Rights'] = @('Modify')
                    }

                    It 'Should throw the correct error' {
                        $mockErrorMessage = $script:localizedData.FailedToSetAccessRules -f $mockPath

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $mockErrorMessage
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
