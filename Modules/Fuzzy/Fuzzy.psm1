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
        if ($index -eq 'a') { $result = Select-Index -Items $Items -All }
        elseif ($index -eq 'q') { return $null }
        else { $result = Select-Index -Items $Items -Index $index }
        return $result
    }
}

function Read-Selection { 
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Items,
        [string]$preview = "cat"
    )    
    $Items | fzf -m --preview "$preview {}"
}

function Select-Item {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Items = (Get-ChildItem -File).FullName,
        [switch]$ByIndex
    )
    begin {
        function Confirm-Fzf { -not $ByIndex -and (Test-Availability) }
    }
    process {
        if (Confirm-Fzf) { $result = Read-Selection -Items $Items }
        else { $result = Read-SelectionByIndex -Items $Items }
        if ($null -ne $result) { $result.Trim() }
    }
}
