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
function Test-FzfAvailability {
    try { fzf --version | Out-Null; return $true }
    catch { return $false }
}
function Select-ByIndex {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Paths,
        [Parameter(ValueFromPipeline)]
        [int]$Index = 0,
        [switch]$All
    )
    process {
        if ($All) { return $Paths }
        elseif ($Index -lt $Paths.Count) { return $Paths[$Index] }
    }
}

function Select-WithFzf { 
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Paths,
        [string]$preview = "cat"
    )    
    $Paths | fzf -m --preview "$preview {}"
}

function Select-File {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Configuration = (New-Configuration),
        [switch]$ByIndex
    )
    begin {
        $paths = $Configuration.Patchs | Select-Object -ExpandProperty FullName
        function Show-Index {
            $index = 0
            $paths | ForEach-Object { Write-Host "[$index]`t$_"; $index++ }
        }
        function Select-Index {
            $index = Read-Host "Select a patch by index or press 'a' to select all or 'q' to quit"
            if ($index -eq 'a') { $result = Select-ByIndex -Paths $paths -All }
            elseif ($index -eq 'q') { return $null }
            else { $result = Select-ByIndex -Paths $paths -Index $index }
            return $result
        }
        function Confirm-Fzf { return -not $ByIndex -and (Test-FzfAvailability) }
    }
    process {
        if (Confirm-Fzf) { $result = Select-WithFzf -Paths $paths }
        else { Show-Index; $result = Select-Index }
        if ($null -ne $result) { return $result.Trim() }
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
        $configuration | Show-DifferenceSummary | Select-WithFzf -preview "git diff"| Out-Difference 
    }
}
