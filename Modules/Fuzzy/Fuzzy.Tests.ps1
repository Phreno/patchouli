BeforeAll { 
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force 
    function New-ListItemMock { param($Count) 0..($Count-1) | ForEach-Object { "file$_"  } }
}


Describe "Fuzzy" {
    Describe "Teste la disponibilite de fzf" {
        Context "Il est possible de recuperer la version de fzf" {
            BeforeAll { Mock -ModuleName Fuzzy fzf { return $true } }
            It "Retourne vrai si fzf est disponible" { Test-FuzzyAvailability | Should -Be $true }
        }
        Context "Il n'est pas possible de recuperer la version de fzf" {
            BeforeAll { Mock -ModuleName Fuzzy fzf { throw "fzf not found" } }
            It "Retourne faux si fzf n'est pas disponible" { Test-FuzzyAvailability | Should -Be $false }
        }
    }
    Describe "Selection par index" {
        Context "Un index peut etre selectionne" {
            It "Retourne le patch par defaut si aucun index n'est disponible" { Select-FuzzyIndex -Items (New-ListItemMock -Count 2)           | Should -Be "file0" }
            It "Retourne le premier patch par index"                          { Select-FuzzyIndex -Items (New-ListItemMock -Count 2) -Index 0  | Should -Be "file0" }
            It "Retourne le second patch par index"                           { Select-FuzzyIndex -Items (New-ListItemMock -Count 2) -Index 1  | Should -Be "file1" }
        }
        Context "Tous les patchs peuvent etre selectionnes" {
            It "Retourne tous les patchs" { Select-FuzzyIndex -All -Items (New-ListItemMock -Count 2) | Should -Be @("file0", "file1") }
        }
    }
    Describe "Lit la selection de l'utilisateur" {
        Context "Lorsque l'utilisateur selectionne un patch" {
            BeforeAll { Mock -ModuleName Fuzzy Read-Host { return 0 } }
            It "Retourne le patch selectionne" { Read-FuzzySelectionByIndex -Items (New-ListItemMock -Count 2) | Should -Be "file0" }
        }
        Context "Lorsque l'utilisateur selectionne tous les patchs" {

        }
        Context "Lorsque l'utilisateur quitte" {

        }
    }

}





# Describe "La selection avec fzf" {
#     Context "Si fzf est disponible" {
#         BeforeAll { Mock -ModuleName Fuzzy fzf { Get-DummyFileName -Index 1    } }
#         BeforeEach { Select-FuzzyWithFzf }
#         It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Fuzzy fzf -Exactly 1 }
#     }
# }

#Describe "La selection par index" {
#    Context "Un id peut etre utilise" {
#        It "Retourne le patch par defaut si aucun index n'est disponible" { Select-PatchByIndex -Paths (New-FileNameMock -Count 2)           | Should -Be "file0.patch" }
#        It "Retourne le premier patch par index"                          { Select-PatchByIndex -Paths (New-FileNameMock -Count 2) -Index 0  | Should -Be "file0.patch" }
#        It "Retourne le second patch par index"                           { Select-PatchByIndex -Paths (New-FileNameMock -Count 2) -Index 1  | Should -Be "file1.patch" }
#    }
#    Context "Tous les patchs peuvent etre selectionnes" {
#        It "Retourne tous les patchs" { Select-PatchByIndex -All -Paths (New-FileNameMock -Count 2) | Should -Be @("file0.patch", "file1.patch") }
#    }
#}

#Describe "La selection de patchs" {
#    Context "Si fzf est disponible" {
#        BeforeAll {
#            Mock -ModuleName Fuzzy Test-FzfAvailability { return $true }
#            Mock -ModuleName Fuzzy Select-WithFzf { return "file1.patch" }
#        }
#        BeforeEach { Select-PatchFile }
#        It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Fuzzy Select-WithFzf -Exactly 1 }
#    }
#    Context "Si fzf n'est pas disponible" {
#        BeforeAll {
#            Mock -ModuleName Fuzzy Test-FzfAvailability { $false         }
#            Mock -ModuleName Fuzzy Select-WithIndex     { "file1.patch"  }
#        }
#        BeforeEach { Select-PatchFile }
#        It "Selectionne par index"                { Assert-MockCalled -ModuleName Fuzzy Select-WithIndex -Exactly 1 }
#        }
#        # It "Affiche les patchs disponibles"       { Assert-MockCalled -ModuleName Fuzzy Write-Host     -Exactly 2 }
#        # It "Lit l'index fourni par l'utilisateur" { Assert-MockCalled -ModuleName Fuzzy Read-Host      -Exactly 1 }
#        #Context "Demande tous les patchs" {
#        #    BeforeAll { Mock -ModuleName Fuzzy Read-Host { return 'a' } }
#        #    It "Retourne tous les patchs" { Assert-MockCalled -ModuleName Fuzzy Select-ByIndex -ParameterFilter { $All -eq $true } -Exactly 1 }
#        #}
#    }
#}
#}
