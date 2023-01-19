<#
    .SYNOPSIS
        Unit test for DSC_FileSystemObject DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'FileSystemDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'FileSystemObject' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [FileSystemObject]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [FileSystemObject]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [FileSystemObject]::new()
                $instance.GetType().Name | Should -Be 'FileSystemObject'
            }
        }
    }
}

Describe 'FileSystemObject\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state'-Skip {

        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockFileSystemObjectInstanceDir = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'directory'
                    DestinationPath = 'C:\MadeUpDir'
                }
                $script:mockFileSystemObjectInstanceDirCopyRecurse = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'directory'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource'
                    Recurse         = $true
                    Force           = $true
                }
                $script:mockFileSystemObjectInstanceDirCopyRecurseWildcard = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'directory'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource\*'
                }
                $script:mockFileSystemObjectInstanceFile = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    DestinationPath = 'C:\MadeUpDir\madeupfile'
                }
                $script:mockFileSystemObjectInstanceFileContent = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    Contents        = 'Ladies and Gentlemen: The Content!'
                    DestinationPath = 'C:\MadeUpDir\madeupfile'
                }
                $script:mockFileSystemObjectInstanceFileCopyDefault = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource\madeupfile'
                }
                $script:mockFileSystemObjectInstanceFileCopyCreation = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource\madeupfile'
                    Checksum        = 'CreationTime'
                }
                $script:mockFileSystemObjectInstanceFileCopyModified = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource\madeupfile'
                    Checksum        = 'LastModifiedTime'
                }
                $script:mockFileSystemObjectInstanceFileCopyWildcard = [FileSystemObject] @{
                    Ensure          = 'present'
                    Type            = 'file'
                    DestinationPath = 'C:\MadeUpDir'
                    SourcePath      = 'D:\MadeUpSource\*file*'
                }

                # Empty hash function results, since system is in desired state
                # GetHash should not be called at any rate, as CompareHash is "mocked"
                foreach ($variable in (Get-Variable -Scope Script -Name mockFileSystemObjectInstance*))
                {
                    $variable.Value | Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetHash' -Value { return }
                    $variable.Value  | Add-Member -Force -MemberType 'ScriptMethod' -Name 'CompareHash' -Value { return }
                }
            }
        }
    }
}

Describe 'FileSystemObject\Set()' -Tag 'Set' -Skip {

}

Describe 'FileSystemObject\Test()' -Tag 'Test' -Skip {

}

Describe 'FileSystemObject\GetHash()' -Tag 'GetHash' -Skip {

}

Describe 'FileSystemObject\CompareHash()' -Tag 'CompareHash' -Skip {

}
