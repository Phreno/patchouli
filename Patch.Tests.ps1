BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force
}

Describe "Construit la configuration" {
    # It "x" { $true | Should -be $false }
    It "Recupere un objet de configuration" { New-PatchConfiguration | Should -BeOfType HashTable }
    It "Retourne le repository git cible" { (New-PatchConfiguration).Repository | Should -BeOfType System.IO.DirectoryInfo }
    It "Permet la Modification du repository git cible" { (New-PatchConfiguration -Repository "./patchouli").Repository.BaseName | Should -Be patchouli }
}
