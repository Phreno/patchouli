BeforeAll { 
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force 
}

Describe "Version" {
    Describe "Teste la modification d'un module" {

        Context "Un module est modifié" {
            BeforeAll { Mock -ModuleName ModuleVersion git { "M some/modified/iles" } }
            It "Retourne vrai si le module est modifié" { Test-ModuleVersionForModification | Should -Be $true }
        }
        Context "Un module n'est pas modifié" {
            BeforeAll { Mock -ModuleName ModuleVersion git { throw "no modification" } }
            It "Retourne faux si le module n'est pas modifié" { Test-ModuleVersionForModification | Should -Be $false }
        }
    }
}
