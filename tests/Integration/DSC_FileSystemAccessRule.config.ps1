$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')

if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'

                <#
                    Paths is set to a correct value in the configuration prior to
                    running each configuration.
                #>
                Path1           = ''
                Path2           = ''
                Path3           = ''

                # User identity used for testing rights
                UserName        = 'NT AUTHORITY\NETWORK SERVICE'

                # Local groups temporarily created for testing rights.
                LocalGroupName1 = 'DscTestGroup1'
                LocalGroupName2 = 'DscTestGroup2'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Create a local group that is used as the identity for some tests.
#>
configuration DSC_FileSystemAccessRule_Prerequisites_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node localhost
    {
        Group 'AddLocalGroup1'
        {
            Ensure      = 'Present'
            GroupName   = $Node.LocalGroupName1
            Description = 'Group for DSC_FileSystemAccessRule tests'
        }

        Group 'AddLocalGroup2'
        {
            Ensure      = 'Present'
            GroupName   = $Node.LocalGroupName2
            Description = 'Group for DSC_FileSystemAccessRule tests'
        }
    }
}

<#
    .SYNOPSIS
        Create new access rule for a user identity on first test path.
#>
configuration DSC_FileSystemAccessRule_NewRulePath1_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Path     = $Node.Path1
            Identity = $Node.UserName
            Rights   = @('Read')
        }
    }
}

<#
    .SYNOPSIS
        Create new access rule for a local group identity on second test path.
#>
configuration DSC_FileSystemAccessRule_NewRulePath2_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Path     = $Node.Path2
            Identity = $Node.LocalGroupName1
            Rights   = @('Modify')
        }
    }
}

<#
    .SYNOPSIS
        Create new access rule for a local group identity on third test path.
#>
configuration DSC_FileSystemAccessRule_NewRulePath3_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Path     = $Node.Path3
            Identity = $Node.LocalGroupName2
            Rights   = @('Read')
        }
    }
}

<#
    .SYNOPSIS
        Adds an access rule for a user identity on the first path.
#>
configuration DSC_FileSystemAccessRule_UpdateRulePath1_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Path     = $Node.Path1
            Identity = $Node.UserName
            Rights   = @('Write')
        }
    }
}

<#
    .SYNOPSIS
        Adds an access rule for a local group identity on the third path.
#>
configuration DSC_FileSystemAccessRule_UpdateRulePath3_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Path     = $Node.Path3
            Identity = $Node.LocalGroupName2
            Rights   = @('FullControl')
        }
    }
}

<#
    .SYNOPSIS
        Removes all access rules for the identity.
#>
configuration DSC_FileSystemAccessRule_RemoveRulePath1_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Ensure   = 'Absent'
            Path     = $Node.Path1
            Identity = $Node.UserName
        }
    }
}

<#
    .SYNOPSIS
        Removes only the specified access rules for the identity when the
        identity in the current state has more rights than desired state.

    .NOTES
        This requires that the identity was assigned the Modify right in
        the previous test, from which we remove the right Write. That should
        result in a different set or rights.
#>
configuration DSC_FileSystemAccessRule_RemoveRulePath2_Config
{
    Import-DscResource -ModuleName 'FileSystemDsc'

    node localhost
    {
        FileSystemAccessRule 'Integration_Test'
        {
            Ensure   = 'Absent'
            Path     = $Node.Path2
            Identity = $Node.LocalGroupName1
            Rights   = @('Write')
        }
    }
}

<#
    .SYNOPSIS
        Removes the local groups that were created.
#>
configuration DSC_FileSystemAccessRule_Cleanup_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node localhost
    {
        Group 'RemoveLocalGroup1'
        {
            Ensure      = 'Absent'
            GroupName   = $Node.LocalGroupName1
        }

        Group 'RemoveLocalGroup2'
        {
            Ensure      = 'Absent'
            GroupName   = $Node.LocalGroupName2
        }
    }
}
