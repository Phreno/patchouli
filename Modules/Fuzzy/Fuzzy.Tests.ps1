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
    Describe "Lit la selection de l'utilisateur par index" {
        Context "Lorsque l'utilisateur selectionne un patch" {
            BeforeAll { Mock -ModuleName Fuzzy Read-Host { 0 } }
            It "Retourne le patch selectionne" { Read-FuzzySelectionByIndex -Items (New-ListItemMock -Count 2) | Should -Be "file0" }
        }
        Context "Lorsque l'utilisateur selectionne tous les patchs" {
            BeforeAll { Mock -ModuleName Fuzzy Read-Host { 'a' } }
            It "Retourne tous les patchs" { Read-FuzzySelectionByIndex -Items (New-ListItemMock -Count 2) | Should -Be @("file0", "file1") }
        }
        Context "Lorsque l'utilisateur quitte" {
            BeforeAll { Mock -ModuleName Fuzzy Read-Host { 'q' } }
            It "Retourne nul" { Read-FuzzySelectionByIndex -Items (New-ListItemMock -Count 2) | Should -Be $null }
        }
    }
    Describe "Lit la selection de l'utilisateur" {
        Context "Lorsque l'utilisateur selectionne un patch" {
            BeforeAll { Mock -ModuleName Fuzzy fzf { return "file1" } }
            BeforeEach { $result = Read-FuzzySelection -Items (New-ListItemMock -Count 1) }
            It "Retourne le patch selectionne" { $result | Should -Be "file1" }
            It "Retourne le patch selectionne" { Assert-MockCalled -ModuleName Fuzzy fzf -Exactly 1 }
        }
    }

    Describe "Selectionne un item" {
            BeforeEach { Select-FuzzyItem }
        Context "Si fzf est disponible" {
            BeforeAll { 
                Mock -ModuleName Fuzzy Test-Availability { return $true }
                Mock -ModuleName Fuzzy Read-Selection { return "file1" }
            }
            It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Fuzzy Read-Selection -Exactly 1 }
        }
        Context "Si fzf n'est pas disponible" {
            BeforeAll {
                Mock -ModuleName Fuzzy Test-Availability { return $false }
                Mock -ModuleName Fuzzy Read-SelectionByIndex { return "file1" } 
            }
            It "Selectionne par index" { Assert-MockCalled -ModuleName Fuzzy Read-SelectionByIndex -Exactly 1 }
        }
    }
}
