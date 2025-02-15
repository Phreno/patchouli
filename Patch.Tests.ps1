BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force
}

Describe "Applique la configuration" {
    It "Recupere un objet de configuration" {
        New-PatchConfiguration | Should -BeOfType HashTable
    }
}
