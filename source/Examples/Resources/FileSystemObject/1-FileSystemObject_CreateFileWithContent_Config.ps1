<#PSScriptInfo
.VERSION 1.0.0
.GUID e479ea7f-abcd-40a5-96ab-17215511b05f
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/FileSystemDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/FileSystemDsc
.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png
.RELEASENOTES
First release.
#>

#Requires -Module FileSystemDsc

<#

.DESCRIPTION
 Sample to create a file with contents.

#>
Configuration FileSystemObject_CreateFileWithContent_Config
{
    Import-DscResource -ModuleName FileSystemDsc

    node localhost
    {
        FileSystemObject MyFile
        {
            DestinationPath = 'C:\inetpub\wwwroot\index.html'
            Contents        = '<html><head><title>My Page</title></head><body>DSC is the best</body></html>'
            Type            = 'file'
            Ensure          = 'present'
        }
    }
}
