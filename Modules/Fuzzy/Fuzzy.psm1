<#
.SYNOPSIS
    A module to provide fuzzy search capabilities using fzf.
.DESCRIPTION
    This module provides functions to interact with fzf to provide fuzzy search capabilities.
    The module provides the following functions:
    - Test-Availability: Tests if fzf is available.
    - Select-Index: Selects an item by index.
    - Read-SelectionByIndex: Reads the user selection by index.
    - Read-Selection: Reads the user selection using fzf.
    - Select-Item: Selects an item using fzf or by index.
.EXAMPLE
    Test-Availability
    Tests if fzf is available.
.EXAMPLE
    Select-Index -Items @("item1", "item2") -Index 1
    Selects the second item from the list.
.EXAMPLE
    Read-SelectionByIndex -Items @("item1", "item2")
    Reads the user selection by index.
.EXAMPLE
    Read-Selection -Items @("item1", "item2")
    Reads the user selection using fzf.
.EXAMPLE
    Select-Item -Items @("item1", "item2")
    Selects an item using fzf or by index.
#>

function Test-Availability {
    <#
    .SYNOPSIS
        Tests if fzf is available.
    .DESCRIPTION
        Tests if fzf is available.
    .EXAMPLE
        Test-Availability
        Tests if fzf is available.
    .OUTPUTS
        System.Boolean
    #>
    begin { $result = $false }
    process {
        try { $result = fzf --version | Out-Null; return $true }
        catch { $result = $false }
    }
    end {
        Write-Debug "Test-Availability? $result"
        $result
    }
}

function Select-Index {
    <#
    .SYNOPSIS
        Selects an item by index.
    .DESCRIPTION
        Selects an item by index.
    .PARAMETER Items
        The list of items to select from.
    .PARAMETER Index
        The index of the item to select.
    .PARAMETER All
        Selects all items.
    .EXAMPLE
        Select-Index -Items @("item1", "item2") -Index 1
        Selects the second item from the list.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Items,
        [Parameter(ValueFromPipeline)]
        [int]$Index = 0,
        [switch]$All
    )
    end {
        Write-Debug "Select-Index: Items count: $($Items.Count)"
        Write-Debug "Select-Index: Index: $Index"
        Write-Debug "Select-Index: All: $All"
        if ($All) { return $Items }
        elseif ($Index -lt $Items.Count) { return $Items[$Index] }
    }
}
function Read-SelectionByIndex {
    <#
    .SYNOPSIS
        Reads the user selection by index.
    .DESCRIPTION
        Reads the user selection by index.
    .PARAMETER Items
        The list of items to select from.
    .EXAMPLE
        Read-SelectionByIndex -Items @("item1", "item2")
        Reads the user selection by index.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Items
    )
    begin {
        Write-Debug "Read-SelectionByIndex: Items count: $($Items.Count)"
        function Show-Index { $index = 0; $Items | ForEach-Object { Write-Host "[$index]`t$_"; $index++ } }
    }
    end {
        $index = Read-Host "Select a patch by index or press 'a' to select all or 'q' to quit"
        if ($index -eq 'a') { $result = Select-Index -Items $Items -All }
        elseif ($index -eq 'q') { return $null }
        else { $result = Select-Index -Items $Items -Index $index }
        return $result
    }
}

function Read-Selection {
    <#
    .SYNOPSIS
        Reads the user selection using fzf.
    .DESCRIPTION
        Reads the user selection using fzf.
    .PARAMETER Items
        The list of items to select from.
    .PARAMETER Preview
        The preview command to display the selected item.
    .EXAMPLE
        Read-Selection -Items @("item1", "item2")
        Reads the user selection using fzf.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $Items,
        [string]$preview = "cat"
    )
    begin { 
        Write-Debug "Read-Selection: Items count: $($Items.Count)" 
        Write-Debug "Read-Selection: Items: $($Items | ConvertTo-Json)" 
        Write-Debug "Read-Selection: Preview: $preview"
    }
    end { $Items | fzf -m --preview "$preview {}" }    
}

function Select-Item {
    <#
    .SYNOPSIS
        Selects an item using fzf or by index.
    .DESCRIPTION
        Selects an item using fzf or by index.
    .PARAMETER Items
        The list of items to select from.
    .PARAMETER ByIndex
        Selects an item by index.
    .PARAMETER Preview
        The preview command to display the selected item.
    .EXAMPLE
        Select-Item -Items @("item1", "item2")
        Selects an item using fzf or by index.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Items = (Get-ChildItem -File).FullName,
        [switch]$ByIndex,
        [string]$Preview = "cat"
    )
    Write-Debug "Select-Item: Items count: $($Items.Count)"
    function Confirm-Fzf { 
        $result = -not $ByIndex -and (Test-Availability) 
        Write-Debug "Confirm-Fzf? $result"
        $result
    }
    if (Confirm-Fzf) { $result = Read-Selection -Items:($Items) -Preview:$Preview }
    else { $result = Read-SelectionByIndex -Items $Items }
    if ($null -ne $result) { $result.Trim() }
}
