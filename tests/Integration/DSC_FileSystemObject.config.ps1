$temproot = Join-Path -Path ([io.Path]::GetTempPath()) -ChildPath DscFileIntTest
$tempdir = Join-Path -Path $temproot -ChildPath Source
$tempDirDestination = Join-Path -Path $temproot -ChildPath Destination
$null = New-Item -ItemType Directory -Path $tempDirDestination -ErrorAction SilentlyContinue

<#
    .SYNOPSIS
        Create empty directory
#>
configuration DSC_FileSystemObject_EmptyDir
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject EmptyDir
        {
            DestinationPath = $tempdir
            Type            = 'directory'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Create an empty file

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_EmptyFile
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject EmptyFile
        {
            DestinationPath = Join-Path -Path $tempdir -ChildPath "emptyfile"
            Type            = 'file'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Create a file with content and encoding utf8

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_CreateFile
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject FileContent
        {
            DestinationPath = Join-Path -Path $tempdir -ChildPath "contentfile"
            Type            = 'file'
            Ensure          = 'present'
            Contents        = 'It works'
            Encoding        = 'utf8'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy single file

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_CopyFile
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject CopyFile
        {
            DestinationPath = Join-Path -Path $tempDirDestination -ChildPath "copiedfile"
            SourcePath      = Join-Path -Path $tempdir -ChildPath "contentfile"
            Type            = 'file'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy several files with wildcard

    .NOTES
        This requires that the temporary dir was created in the very first test
        and that files were created in previous tests
#>
configuration DSC_FileSystemObject_CopyFileWildcard
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject CopyFile
        {
            DestinationPath = Join-Path -Path $tempDirDestination -ChildPath "copydestfilewc"
            SourcePath      = Join-Path -Path $tempdir -ChildPath "*file"
            Type            = 'file'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy single directory

    .NOTES
        This requires that the temporary dir was created in the very first test
        and files were created in previous tests
#>
configuration DSC_FileSystemObject_CopyDir
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject CopyDir
        {
            DestinationPath = $tempDirDestination
            SourcePath      = $tempdir
            Type            = 'directory'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy directories using a wildcard pattern

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_CopyDirWildcard
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject CopyDirWc
        {
            DestinationPath = $tempDirDestination
            SourcePath      = Join-Path -Path $tempdir -ChildPath "*"
            Type            = 'directory'
            Ensure          = 'present'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy single directory recursively

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_CopyDirRecurse
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject CopyDirRec
        {
            DestinationPath = $tempDirDestination
            SourcePath      = $tempdir
            Type            = 'directory'
            Ensure          = 'present'
            Recurse         = $true
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Copy directory recursive using wildcard pattern

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_CopyDirRecurseWildcard
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject SourceObject
        {
            DestinationPath = Join-Path -Path $tempDir -ChildPath 'this\is\recursive'
            Type            = 'file'
            Ensure          = 'present'
            Recurse         = $true
            Force           = $true
        }

        FileSystemObject CopyDirRecWc
        {
            DestinationPath = $tempDirDestination
            SourcePath      = Join-Path -Path $tempdir -ChildPath "*"
            Type            = 'directory'
            Ensure          = 'present'
            Recurse         = $true
            Force           = $true
            DependsOn       = '[FileSystemObject]SourceObject'
        }
    }
}

<#
    .SYNOPSIS
        Remove a single file

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_RemoveFile
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject EmptyFile
        {
            DestinationPath = Join-Path -Path $tempdir -ChildPath "emptyfile"
            Type            = 'file'
            Ensure          = 'absent'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Remove files using a wildcard pattern

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_RemoveFileWildcard
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject RemoveFileWc
        {
            DestinationPath = Join-Path -Path $tempdir -ChildPath "copydestfilewc\*"
            Type            = 'file'
            Force           = $true
            Ensure          = 'absent'
        }
    }
}

<#
    .SYNOPSIS
        Remove the temporary directory, thereby cleaning up all test files

    .NOTES
        This requires that the temporary dir was created in the very first test
#>
configuration DSC_FileSystemObject_RemoveDirRecurse
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject RemoveDirRecurse
        {
            DestinationPath = $tempRoot
            Type            = 'file'
            Ensure          = 'absent'
            Force           = $true
            Recurse         = $true
        }
    }
}
