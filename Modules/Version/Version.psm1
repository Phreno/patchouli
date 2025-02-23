function Update-ModuleVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ManifestPath,
        [switch]$Force
    )
    Write-Debug "Mise à jour de la version du module: $ManifestPath"
    $isModified = $null -ne (git status --porcelain "$ManifestPath")
    
    if (-not $isModified -and -not $Force) {
        Write-Debug "Module non modifié, pas de mise à jour"
        return
    }
    $manifest = Import-PowerShellDataFile $manifestPath
    
    $currentVersion = [System.Version]$manifest.ModuleVersion
    
    $newVersion = [System.Version]::new(
        $currentVersion.Major,
        $currentVersion.Minor,
        $currentVersion.Build + 1
    )
    
    Write-Debug "Version actuelle: $currentVersion"
    Write-Debug "Nouvelle version: $newVersion"
    
    Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion
    
    Write-Output "Version mise à jour: $newVersion"
}


function Show-ModifiedModules {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ModulePath = "."
    )
    Write-Debug "Recherche des modules modifiés"
    $modules = Get-ChildItem -Path $ModulePath -Filter "*.psd1" -Recurse
    $modules | ForEach-Object {
        Write-Debug "Vérification du module: $($_.FullName)"
        $isModified = (git status --porcelain $_.Directory.FullName ) -ne $null
        if ($isModified) { Write-Output $_.FullName }
    }
}
function Update-ForAllModifiedModules {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ModulePath = "."
    )
    Write-Output "Mise à jour des modules modifiés"
    Show-ModifiedModules -ModulePath $ModulePath | 
    ForEach-Object { Update-ModuleVersion -ManifestPath $_ }
}