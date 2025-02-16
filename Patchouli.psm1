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
function Select-File {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Configuration = (New-Configuration)
    )
    begin {
        function Select-WithFzf { $Configuration.Patchs | Select-Object -ExpandProperty FullName | fzf }
    }
    process {
        if (Test-FzfAvailability) { $result = Select-WithFzf }
        else { $result = "file1.patch" }
        if ($null -ne $result) { return $result.Trim() }
        return $null
    }
}
