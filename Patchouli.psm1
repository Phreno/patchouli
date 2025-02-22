function New-Configuration {
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
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [hashtable]$Configuration = (New-Configuration)
    )
    begin {
        $currentPath = Get-Location
        Set-Location $Configuration.Repository.FullName
    }
    process { git diff --name-only }
    end { Set-Location $currentPath }
}


function Out-Difference {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$file
    )
    process { git diff -p $file | Out-File "$file.patch" }
}

function New-Diff {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [hashtable]$Configuration = (New-Configuration)
    )
    process {
        $configuration | Show-DifferenceSummary | Select-File | Out-Difference
    }
}
