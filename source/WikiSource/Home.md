# Welcome to the FileSystemDsc wiki

<sup>*FileSystemDsc v#.#.#*</sup>

Here you will find all the information you need to make use of the FileSystemDsc
DSC resources in the latest release. This includes details of the resources
that are available, current capabilities, known issues, and information to
help plan a DSC based implementation of FileSystemDsc.

Please leave comments, feature requests, and bug reports for this module in
the [issues section](https://github.com/dsccommunity/FileSystemDsc/issues)
for this repository.

## Getting started

To get started either:

- Install from the PowerShell Gallery using PowerShellGet by running the
  following command:

```powershell
Install-Module -Name FileSystemDsc -Repository PSGallery
```

- Download FileSystemDsc from the [PowerShell Gallery](https://www.powershellgallery.com/packages/FileSystemDsc)
  and then unzip it to one of your PowerShell modules folders (such as
  `$env:ProgramFiles\WindowsPowerShell\Modules`).

To confirm installation, run the below command and ensure you see the FileSystemDsc
DSC resources available:

```powershell
Get-DscResource -Module FileSystemDsc
```

## Prerequisites

The minimum Windows Management Framework (PowerShell) version required is 5.0
or higher, which ships with Windows 10 or Windows Server 2016,
but can also be installed on Windows 7 SP1, Windows 8.1, Windows Server 2012,
and Windows Server 2012 R2.

## Change log

A full list of changes in each version can be found in the [change log](https://github.com/dsccommunity/FileSystemDsc/blob/main/CHANGELOG.md).
