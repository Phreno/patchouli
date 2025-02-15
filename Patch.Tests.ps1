BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force
}

Describe "La configuration du patch" {
    It "Recupere un objet de configuration" { New-PatchConfiguration | Should -BeOfType HashTable }
    It "Retourne le repository git cible" { (New-PatchConfiguration).Repository | Should -BeOfType System.IO.DirectoryInfo }
    It "Permet la Modification du repository git cible" {
        (New-PatchConfiguration -Repository $PSScriptRoot).Repository.BaseName | Should -Be patchouli
        (New-PatchConfiguration -Repository "../").Repository.BaseName | Should -Not -Be patchouli 
    }
    It "Assure que le repository git cible soit valide" {
        "$((New-PatchConfiguration).Repository)/.git" | Test-Path | Should -Be $True 
    }
}
