<#
.SYNOPSIS
    This module is a wrapper around git diff command to create patch files.
.DESCRIPTION
    This module provides functions to create patch files from git diff command.
    The module provides the following functions:
    - New-Configuration: Creates a new configuration object.
    - Show-DifferenceSummary: Shows the difference summary.
    - Out-Difference: Outputs the difference to a patch file.
    - New-Diff: Creates a new patch file.
#>
function New-Configuration {
    <#
    .SYNOPSIS
        Creates a new configuration object.
    .DESCRIPTION
        Creates a new configuration object.
    .PARAMETER Repository
        The repository to use.
    .PARAMETER Patchs
        The patch files to use. A list of patch files.
    .EXAMPLE
        New-Configuration
        Creates a new configuration object.
    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    Param(
        [ValidateScript({ Test-Path "$_/.git" -PathType Container })]
        [Parameter(ValueFromPipeline)]$Repository = "./",
        [ValidateScript({ Test-Path $_ -PathType Container })]
        $Patchs = $Repository  
    )
    @{ 
        Repository = ($Repository | Get-Item );
        Patchs     = ($Patchs | Get-ChildItem -Filter *.patch -Recurse)
    }
}


function Show-DifferenceSummary {
    <#
    .SYNOPSIS
        Shows the difference summary.
    .DESCRIPTION
        Shows the files that have been modified since the last commit.
    .PARAMETER Configuration
        The configuration object.
    .EXAMPLE
        Show-DifferenceSummary
        Shows the difference summary.
    .OUTPUTS
        String[]
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        $Configuration = (New-Configuration)
    )
    begin {
        $currentPath = Get-Location
        Set-Location $Configuration.Repository.FullName
    }
    process { git diff --name-only }
    end { Set-Location $currentPath }
}


function Out-Difference {
    <#
    .SYNOPSIS
        Outputs the difference to a patch file.
    .DESCRIPTION
        Outputs the difference to a patch file.
    .PARAMETER File
        The file to output the difference to.
    .EXAMPLE
        Show-DifferenceSummary | Select-FuzzyItem | Out-Difference
        Outputs the difference to a patch file.
    .OUTPUTS
        System.IO.FileInfo
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$file
    )
    process { git diff -p $file | Out-File "$file.patch" }
}


function Select-Item {
    <#
    .SYNOPSIS
        Selects an item from a list.
    .DESCRIPTION
        Proxy for Select-FuzzyItem in the Fuzzy module. (In order to make it easier to test)
    .PARAMETER Items
        The items to select from.
    .EXAMPLE
        Show-DifferenceSummary | Select-Item
        Selects an item from a list.
    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        $Items
    )
    Select-FuzzyItem -preview "git diff" -Items $Items
}


function New-Diff {
    <#
    .SYNOPSIS
        Creates a new patch file.
    .DESCRIPTION
        Creates a new patch file by looking at the difference between the current state and the last commit.
    .PARAMETER Configuration
        The configuration object. See New-Configuration.
    .EXAMPLE
        New-Diff
        Creates a new patch file.
    .OUTPUTS
        System.IO.FileInfo[]
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        $Configuration = (New-Configuration)
    )
    Write-Debug "Configuration: $Configuration"
    $patches = Select-Item -Items ($configuration | Show-DifferenceSummary)
    $patches | Out-Difference
    $patches | ForEach-Object { Get-Item "$_.patch" }
}
