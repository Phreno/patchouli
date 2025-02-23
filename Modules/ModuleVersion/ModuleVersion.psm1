function Update-ModuleVersion {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ManifestPath
    )
    Write-Debug "Mise à jour de la version du module: $ManifestPath"
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
    
    Write-Output "Version mise à jour: $manifestPath $newVersion"
}

function Test-ForModification {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ModulePath = "."
    )
    Write-Debug "Recherche de modifications pour le module: $ModulePath"
    try { $nul -ne (git status --porcelain $_.Directory.FullName ) }
    catch { $false }
}

function Show-Modified {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ModulePath = "."
    )
    Write-Debug "Recherche des modules modifiés"
    Get-ChildItem -Path $ModulePath -Filter "*.psd1" -Recurse | Where-Object { Test-ForModification -ModulePath $_.Directory.FullName }
}

function Update-ForAllModified {
    [CmdletBinding(supportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$ModulePath = "."
    )
    Write-Output "Mise à jour des modules modifiés"
    Show-Modified | ForEach-Object { Update-ModuleVersion -ManifestPath $_ }
}