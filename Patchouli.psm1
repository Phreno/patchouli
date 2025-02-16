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


function Select-File {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [hashtable]$Configuration = (New-Configuration)
    )
    process {
        if ($null -eq $Configuration.Patchs) {
            Write-Warning "Aucun patch trouvé"
            return $null
        }
        $result = $Configuration.Patchs | 
            Select-Object -ExpandProperty Name | fzf
        if ($null -ne $result) { return $result.Trim() }
        return $null
    }
}
