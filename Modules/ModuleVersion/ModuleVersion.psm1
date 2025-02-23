#function Update-ModuleVersion {
    #[CmdletBinding()]
    #param(
        #[Parameter(Mandatory, ValueFromPipeline)]
        #[string]$ManifestPath,
        #[switch]$Force
    #)
    #Write-Debug "Mise à jour de la version du module: $ManifestPath"
    #Write-Debug "Forcer la mise à jour: $Force"
    #$isModified = $null -ne (git status --porcelain "$ManifestPath")
    #
    #if (-not $isModified -and -not $Force) {
        #Write-Debug "Module non modifié, pas de mise à jour"
        #return
    #}
    #$manifest = Import-PowerShellDataFile $manifestPath
    #
    #$currentVersion = [System.Version]$manifest.ModuleVersion
    #
    #$newVersion = [System.Version]::new(
        #$currentVersion.Major,
        #$currentVersion.Minor,
        #$currentVersion.Build + 1
    #)
    #
    #Write-Debug "Version actuelle: $currentVersion"
    #Write-Debug "Nouvelle version: $newVersion"
    #
    #Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion
    #
    #Write-Output "Version mise à jour: $newVersion"
#}

function Test-ForModification {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path "$_/.git" -PathType Container })]
        [string]$ModulePath = "."
    )
    Write-Debug "Recherche de modifications pour le module: $ModulePath"
    try { $nul -ne (git status --porcelain $_.Directory.FullName ) }
    catch { $false }
}

#function Show-ModifiedModules {
    #[CmdletBinding()]
    #param(
        #[Parameter(ValueFromPipeline)]
        #[string]$ModulePath = "."
    #)
    #Write-Debug "Recherche des modules modifiés"
#}

#function Update-ForAllModifiedModules {
    #[CmdletBinding()]
    #param(
        #[Parameter(ValueFromPipeline)]
        #[string]$ModulePath = "."
    #)
    #Write-Output "Mise à jour des modules modifiés"
    #Show-ModifiedModules | ForEach-Object { Update-ModuleVersion -ManifestPath $_ }
#}