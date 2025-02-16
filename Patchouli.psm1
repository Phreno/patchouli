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
    process {
        if (-not $ByIndex -and (Test-FzfAvailability)) { $result = Select-WithFzf -Configuration $Configuration }
        else { 
            $index = 0
            $Configuration.Patchs | ForEach-Object { Write-Host "[$index]`t$($_.FullName)"; $index++ }
            $index = Read-Host "Select a patch by index"
            $result = Select-ByIndex -Configuration $Configuration -Index $index}
        if ($null -ne $result) { return $result.Trim() }
        return $null
    }
}
