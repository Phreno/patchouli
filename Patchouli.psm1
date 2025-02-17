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
        [ValidateNotNullOrEmpty()]
        [hashtable]$Configuration = (New-Configuration),
        [Parameter(ValueFromPipeline)]
        [int]$Index = 0,
        [switch]$All
    )
    process {
        if ($All) { return $Configuration.Patchs.FullName }
        elseif ($Index -lt $Configuration.Patchs.Count) { return $Configuration.Patchs[$Index].FullName }
        return $null
    }
}


function Select-WithFzf { 
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Configuration = (New-Configuration)
    )    
    $Configuration.Patchs | Select-Object -ExpandProperty FullName | fzf -m --preview "cat {}"
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
        function Show-Index {
            $index = 0
            $Configuration.Patchs | ForEach-Object { Write-Host "[$index]`t$($_.FullName)"; $index++ }
        }
        function Select-Index {
            $index = Read-Host "Select a patch by index or press 'a' to select all or 'q' to quit"
            if ($index -eq 'a') { $result = Select-ByIndex -Configuration $Configuration -All }
            elseif ($index -eq 'q') { return $null }
            else { $result = Select-ByIndex -Configuration $Configuration -Index $index}
            return $result
        }
        function Confirm-Fzf { return -not $ByIndex -and (Test-FzfAvailability) }

    }
    process {
        if (Confirm-Fzf) { $result = Select-WithFzf -Configuration $Configuration }
        else { Show-Index; $result = Select-Index }
        if ($null -ne $result) { return $result.Trim() }
    }
}

function New-File {
    git diff --name-only #| Select-Object -Unique | fzf -m --preview "cat {}"
}
