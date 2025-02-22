function Test-Availability {
    try { fzf --version | Out-Null; return $true }
    catch { return $false }
}

function Select-Index {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Items,
        [Parameter(ValueFromPipeline)]
        [int]$Index = 0,
        [switch]$All
    )
    process {
        if ($All) { return $Items }
        elseif ($Index -lt $Items.Count) { return $Items[$Index] }
    }
}
function Read-SelectionByIndex {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Items
    )
    begin {
        function Show-Index { $index = 0; $Items | ForEach-Object { Write-Host "[$index]`t$_"; $index++ } }
    }
    process {
        $index = Read-Host "Select a patch by index or press 'a' to select all or 'q' to quit"
        if ($index -eq 'a') { $result = Select-Index -Itemes $Items -All }
        elseif ($index -eq 'q') { return $null }
        else { $result = Select-Index -Items $Items -Index $index }
        return $result
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
        function Confirm-Fzf { return -not $ByIndex -and (Test-FzfAvailability) }
    }
    process {
        if (Confirm-Fzf) { $result = Select-WithFzf -Paths $paths }
        else { $result = Select-WithIndex }
        if ($null -ne $result) { return $result.Trim() }
    }
}
