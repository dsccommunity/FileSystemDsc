BeforeDiscovery {
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'FileSystemDsc'
    $script:dscResourceName = 'DSC_FileSystemAccessRule'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_FileSystemAccessRule\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockIdentity = 'NT AUTHORITY\NETWORK SERVICE'

        <#
            The filesystem doesn't return a string array for ACLs, it returns a
            bit-flagged [System.Security.AccessControl.FileSystemRights].
        #>
        $mockFileSystemRights = [System.Security.AccessControl.FileSystemRights] @('ReadData', 'WriteAttributes')

        $mockPath = $TestDrive

        $inModuleScopeParameters = @{
            MockPath     = $mockPath
            MockIdentity = $mockIdentity
        }

        InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
            # This should be able to be removed in a future version of Pester.
            param
            (
                $MockPath,
                $MockIdentity
            )

            $script:mockPath = $MockPath
            $script:mockIdentity = $MockIdentity

            $script:mockGetTargetResourceParameters = @{
                Path     = $MockPath
                Identity = $MockIdentity
                Verbose  = $true
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the configuration is absent' {
            Context 'When the node does not belong to a cluster' {
                BeforeAll {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-ACLAccess

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }

                    Mock -CommandName Get-CimInstance
                }

                It 'Should not throw and output the correct warning message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { $script:mockGetTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_Cluster'
                    } -Exactly -Times 1 -Scope It
                }

                It 'Should return the state as absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Path | Should -Be $mockPath
                        $script:mockGetTargetResourceResult.Identity | Should -Be $mockIdentity
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Rights | Should -BeNullOrEmpty
                        $script:mockGetTargetResourceResult.IsActiveNode | Should -BeTrue
                    }
                }
            }

            Context 'When no cluster disk partition is found that uses the path' {
                BeforeAll {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-ACLAccess
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
                    InModuleScope -ScriptBlock {
                        { $script:mockGetTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_Cluster'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_ClusterDiskPartition'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimAssociatedInstance -Exactly -Times 0 -Scope It

                    Should -Invoke -CommandName Write-Warning -ParameterFilter {
                        $localizedString = InModuleScope -ScriptBlock {
                            $script:localizedData.PathDoesNotExist
                        }

                        $Message -eq ($localizedString -f $mockPath)
                    } -Exactly -Times 1 -Scope It
                }

                It 'Should return the state as absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Path | Should -Be $mockPath
                        $script:mockGetTargetResourceResult.Identity | Should -Be $mockIdentity
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Rights | Should -BeNullOrEmpty
                        $script:mockGetTargetResourceResult.IsActiveNode | Should -BeTrue
                    }
                }
            }
        }

        Context 'When the current node is not a possible cluster resource owner' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Get-ACLAccess
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
                    InModuleScope -ScriptBlock {
                        { $script:mockGetTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_Cluster'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_ClusterDiskPartition'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                        $ResultClassName -eq 'MSCluster_Resource'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                        $Association -eq 'MSCluster_ResourceToPossibleOwner'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Write-Warning -ParameterFilter {
                        $localizedString = InModuleScope -ScriptBlock {
                            $script:localizedData.PathDoesNotExist
                        }

                        $Message -eq ($localizedString -f $mockPath)
                    } -Exactly -Times 1 -Scope It
                }

                It 'Should return the state as absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Path | Should -Be $mockPath
                        $script:mockGetTargetResourceResult.Identity | Should -Be $mockIdentity
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Rights | Should -BeNullOrEmpty
                        $script:mockGetTargetResourceResult.IsActiveNode | Should -BeTrue
                    }
                }
            }

            Context 'When the configuration is present' {
                Context 'When the path exists' {
                    BeforeAll {
                        Mock -CommandName Get-ACLAccess -MockWith {
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
                    InModuleScope -ScriptBlock {
                        { $script:mockGetTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 1 -Scope It
                }

                It 'Should return the state as present' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Path | Should -Be $mockPath
                        $script:mockGetTargetResourceResult.Identity | Should -Be $mockIdentity
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Rights | Should -HaveCount 2
                        $script:mockGetTargetResourceResult.Rights | Should -Contain 'ReadData'
                        $script:mockGetTargetResourceResult.Rights | Should -Contain 'WriteAttributes'
                        $script:mockGetTargetResourceResult.IsActiveNode | Should -BeTrue
                    }
                }
            }

            Context 'When path is not found on the node, but the path is found in a cluster disk partition and the current node is a possible cluster resource owner' {
                BeforeAll {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-ACLAccess
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
                    InModuleScope -ScriptBlock {
                        { $script:mockGetTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_Cluster'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'MSCluster_ClusterDiskPartition'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                        $ResultClassName -eq 'MSCluster_Resource'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Get-CimAssociatedInstance -ParameterFilter {
                        $Association -eq 'MSCluster_ResourceToPossibleOwner'
                    } -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
                }

                It 'Should return the state as present' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Path | Should -Be $mockPath
                        $script:mockGetTargetResourceResult.Identity | Should -Be $mockIdentity
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        $script:mockGetTargetResourceResult.Rights | Should -BeNullOrEmpty
                        $script:mockGetTargetResourceResult.IsActiveNode | Should -BeFalse
                    }
                }
            }
        }
    }
}

Describe 'DSC_FileSystemAccessRule\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        $mockIdentity = 'NT AUTHORITY\NETWORK SERVICE'

        $mockPath = $TestDrive

        $inModuleScopeParameters = @{
            MockPath     = $mockPath
            MockIdentity = $mockIdentity
        }

        InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
            # This should be able to be removed in a future version of Pester.
            param
            (
                $MockPath,
                $MockIdentity
            )

            $script:mockPath = $MockPath
            $script:mockIdentity = $MockIdentity

            $script:mockDefaultParameters = @{
                Path     = $MockPath
                Identity = $MockIdentity
                Verbose  = $true
            }
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
        }

        It 'Should return the state as $true' {
            InModuleScope -ScriptBlock {
                $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                $mockTestTargetResourceParameters['Rights'] = @('ReadData')
                $mockTestTargetResourceParameters['ProcessOnlyOnActiveNode'] = $true

                Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
            }
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
                }

                It 'Should return the state as $true' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $mockTestTargetResourceParameters['Rights'] = @('ReadData')

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                    }
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
                }

                It 'Should return the state as $true' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $mockTestTargetResourceParameters['Rights'] = @('Modify')

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                    }
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
            }

            It 'Should return the state as $true' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockTestTargetResourceParameters['Rights'] = @('ReadData')

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeTrue
                }
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
            }

            It 'Should return the state as $false' {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                    $mockTestTargetResourceParameters['Rights'] = @('ReadData')

                    Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                }
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
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Absent'

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                    }
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
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $mockTestTargetResourceParameters['Rights'] = @('ReadData')

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                    }
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
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Present'

                        $mockErrorMessage = $script:localizedData.NoRightsWereSpecified -f $mockIdentity, $mockPath

                        { Test-TargetResource @mockTestTargetResourceParameters } |
                            Should -Throw -ExpectedMessage ($mockErrorMessage + '*')
                    }
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
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Rights'] = @('ReadData')

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                    }
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
                }

                It 'Should return the state as $false' {
                    InModuleScope -ScriptBlock {
                        $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockTestTargetResourceParameters['Ensure'] = 'Present'
                        $mockTestTargetResourceParameters['Rights'] = @('Modify')

                        Test-TargetResource @mockTestTargetResourceParameters | Should -BeFalse
                    }
                }
            }
        }
    }
}

Describe 'DSC_FileSystemAccessRule\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        $mockIdentity = 'NT AUTHORITY\NETWORK SERVICE'

        <#
            The filesystem doesn't return a string array for ACLs, it returns a
            bit-flagged [System.Security.AccessControl.FileSystemRights].
        #>
        $mockFileSystemRights = [System.Security.AccessControl.FileSystemRights] @('ReadData', 'WriteAttributes')

        $mockPath = $TestDrive

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
                            InModuleScope -ScriptBlock {
                                $script:SetAccessRuleMethodCallCount += 1
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name "PurgeAccessRules" -Value {
                            InModuleScope -ScriptBlock {
                                $script:PurgeAccessRulesMethodCallCount += 1
                            }
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name "RemoveAccessRule" -Value {
                            InModuleScope -ScriptBlock {
                                $script:RemoveAccessRuleMethodCallCount += 1
                            }
                        } -PassThru -Force
        }

        Mock -CommandName Get-ACLAccess -MockWith $mockGetAcl
        Mock -CommandName Set-Acl

        $inModuleScopeParameters = @{
            MockPath     = $mockPath
            MockIdentity = $mockIdentity
        }

        InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
            # This should be able to be removed in a future version of Pester.
            param
            (
                $MockPath,
                $MockIdentity
            )

            $script:mockPath = $MockPath
            $script:mockIdentity = $MockIdentity

            $script:mockDefaultParameters = @{
                Path     = $MockPath
                Identity = $MockIdentity
                Verbose  = $true
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:SetAccessRuleMethodCallCount = 0
            $script:PurgeAccessRulesMethodCallCount = 0
            $script:RemoveAccessRuleMethodCallCount = 0
        }
    }

    Context 'When the specified path is missing' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                $mockSetTargetResourceParameters['Rights'] = @('ReadData')

                $mockErrorMessage = $script:localizedData.PathDoesNotExist -f $mockPath

                # Ignore the kind of exception type that is thrown in the exception message.
                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'When not passing the parameter Rights' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()

                $mockErrorMessage = $script:localizedData.NoRightsWereSpecified -f $mockIdentity, $mockPath

                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage + '*')
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the configuration should be absent' {
            Context 'When the specific permissions should be absent' {
                It 'Should call the correct methods and mocks to remove the permissions' {
                    InModuleScope -ScriptBlock {
                        $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                        $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                        $mockSetTargetResourceParameters['Rights'] = @('ReadData', 'Delete')

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        $script:SetAccessRuleMethodCallCount | Should -Be 0
                        $script:PurgeAccessRulesMethodCallCount | Should -Be 0
                        $script:RemoveAccessRuleMethodCallCount | Should -Be 2
                    }

                    Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 1 -Scope It

                    Should -Invoke -CommandName Set-Acl -Exactly -Times 1 -Scope It
                }
            }

            Context 'When all the permissions for the identity should be purged' {
                Context 'When the parameter Rights is set to an empty hashtable' {
                    It 'Should call the correct methods and mocks to remove the permissions' {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockSetTargetResourceParameters['Ensure'] = 'Absent'
                            $mockSetTargetResourceParameters['Rights'] = @()

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            $script:SetAccessRuleMethodCallCount | Should -Be 0
                            $script:PurgeAccessRulesMethodCallCount | Should -Be 1
                            $script:RemoveAccessRuleMethodCallCount | Should -Be 0
                        }

                        Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Set-Acl -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the parameter Rights is not specified' {
                    It 'Should call the correct methods and mocks to remove the permissions' {
                        InModuleScope -ScriptBlock {
                            $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                            $mockSetTargetResourceParameters['Ensure'] = 'Absent'

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            $script:SetAccessRuleMethodCallCount | Should -Be 0
                            $script:PurgeAccessRulesMethodCallCount | Should -Be 1
                            $script:RemoveAccessRuleMethodCallCount | Should -Be 0
                        }

                        Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName Set-Acl -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When the configuration should be present' {
            It 'Should call the correct methods and mocks to set the permissions' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockSetTargetResourceParameters['Rights'] = @('Modify')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:SetAccessRuleMethodCallCount | Should -Be 1
                    $script:PurgeAccessRulesMethodCallCount | Should -Be 0
                    $script:RemoveAccessRuleMethodCallCount | Should -Be 0
                }

                Should -Invoke -CommandName Get-ACLAccess -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-Acl -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the access rules fails to be set' {
            BeforeAll {
                Mock -CommandName Set-Acl -MockWith {
                    throw
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
                    $mockSetTargetResourceParameters['Rights'] = @('Modify')

                    $mockErrorMessage = $script:localizedData.FailedToSetAccessRules -f $mockPath

                    <#
                        Ignore the kind of exception type that is thrown in the exception message.
                        And ignore the inner exceptions that is passed onto the string.
                    #>
                    { Set-TargetResource @mockSetTargetResourceParameters } |
                        Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
                }
            }
        }
    }
}

Describe 'DSC_FileSystemAccessRule\Get-ACLAccess' -Tag 'Helper' {
    BeforeAll {
        $mockIdentity = 'NT AUTHORITY\NETWORK SERVICE'
        $mockFileSystemRights = [System.Security.AccessControl.FileSystemRights] @('ReadData', 'WriteAttributes')

        Mock -CommandName Get-Item -MockWith {
            return New-Object -TypeName PSObject |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetAccessControl' -Value {
                    return New-Object -TypeName PSObject |
                        # Regression test for issue #3
                        Add-Member -MemberType 'NoteProperty' -Name 'Owner' -Value $null -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Access' -Value @(
                            New-Object -TypeName PSObject |
                                Add-Member -MemberType 'NoteProperty' -Name 'IdentityReference' -Value $mockIdentity -PassThru |
                                Add-Member -MemberType 'NoteProperty' -Name 'FileSystemRights' -Value $mockFileSystemRights -PassThru -Force
                            ) -PassThru -Force
                        } -PassThru -Force
        }
    }

    It 'Should return the correct access control list (ACL)' {
        $inModuleScopeParameters = @{
            MockFileSystemRights = $mockFileSystemRights
            MockIdentity         = $mockIdentity
        }

        InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
            # This should be able to be removed in a future version of Pester.
            param
            (
                $MockFileSystemRights,
                $MockIdentity
            )

            Set-StrictMode -Version 1.0

            $result = Get-ACLAccess -Path 'AnyPath'

            $result.Access[0].IdentityReference | Should -Be $mockIdentity
            $result.Access[0].FileSystemRights | Should -Be $MockFileSystemRights

            # Regression test for issue #3
            $result.Owner | Should -BeNullOrEmpty
        }
    }
}
