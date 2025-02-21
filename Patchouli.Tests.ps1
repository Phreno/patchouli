BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force

    function Get-DummyFileName {
        param( $index = 1)
        "file$index.patch"
    }

    function New-FileMock {
        param( [string]$count = 1)
        for ($i = 1; $i -le $count; $i++) { [PSCustomObject]@{ Name = Get-DummyFileName -index $i; FullName = "/fullname/$(Get-DummyFileName -index $i)" } }
    }
}

Describe "La configuration du patch" {
    It "Recupere un objet de configuration" { New-PatchConfiguration | Should -BeOfType HashTable }
    Describe "La propriete Patchs" {
        Context "Le repository git contient des patchs" {
            BeforeAll { Mock -ModuleName Patchouli Get-ChildItem { return New-FileMock -Count 2 } -ParameterFilter { $Filter -eq "*.patch" } }
            BeforeEach { $result = New-PatchConfiguration }
            It "Recupere les patchs du repository git" { 
                $result.Patchs.Count | Should -Be 2
                $result.Patchs[0].Name | Should -Be (Get-DummyFileName -index 1)
            }
        }

        Context "Le repository git ne contient pas de patchs" {
            BeforeAll { Mock -ModuleName Patchouli Get-ChildItem { return @() } -ParameterFilter { $Filter -eq "*.patch" } }
            BeforeEach { $result = New-PatchConfiguration }
            It "Retourne un tableau vide" { $result.Patchs | Should -BeNullOrEmpty }
        }
    }
    Describe "La propriete Repository" {
        Context "Le repository git est valide" {
            BeforeAll { Mock -ModuleName Patchouli Test-Path { return $true } }
            # TODO: Tests a revoir
            It "Retourne le repository git cible" { (New-PatchConfiguration).Repository | Should -BeOfType System.IO.DirectoryInfo }
            It "Permet la Modification du repository git cible" {
                (New-PatchConfiguration -Repository "./").Repository.BaseName | Should -Be patchouli
                (New-PatchConfiguration -Repository "../").Repository.BaseName | Should -Not -Be patchouli 
            }
        }
        Context "Le repository git est invalide" {
            It "Intercepte une erreur" {
                { New-PatchConfiguration -Repository "/this/directory/does/not/exists" } | Should -Throw
            }
        }
    }
}

Describe "La selection avec fzf" {
    Context "Si fzf est disponible" {
        BeforeAll {
            Mock -ModuleName Patchouli New-Configuration { return @{ Patchs = New-FileMock -Count 1 } }
            Mock -ModuleName Patchouli Select-Object { return "file1.patch" } -ParameterFilter { $ExpandProperty -eq "FullName" }
            Mock -ModuleName Patchouli fzf { return Get-DummyFileName -Count 1 }
        }
        BeforeEach { Select-PatchWithFzf }
        It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Patchouli fzf -Exactly 1 }
    }
}

Describe "La selection par index" {
    Context "Un id peut etre utilise" {
        It "Retourne le patch par defaut si aucun index n'est disponible" { Select-PatchByIndex -Paths @("file1.patch", "file2.patch") | Should -Be "file1.patch" }
        It "Retourne le premier patch par index" { Select-PatchByIndex -Index 0  -Paths @("file1.patch", "file2.patch") | Should -Be "file1.patch" }
        It "Retourne le second patch par index" { Select-PatchByIndex -Index 1 -Paths @("file1.patch", "file2.patch") | Should -Be "file2.patch" }
    }
    Context "Tous les patchs peuvent etre selectionnes" {
        It "Retourne tous les patchs" { Select-PatchByIndex -All -Paths @("file1.patch", "file2.patch") | Should -Be @("file1.patch", "file2.patch") }
    }
}

Describe "La selection de patchs" {
    Context "Si fzf est disponible" {
        BeforeAll {
            Mock -ModuleName Patchouli Test-FzfAvailability { return $true }             
            Mock -ModuleName Patchouli Select-WithFzf { return "file1.patch" }
        }
        BeforeEach { Select-PatchFile }
        It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Patchouli Select-WithFzf -Exactly 1 }
    }
    Context "Si fzf n'est pas disponible" {
        BeforeAll {
            Mock -ModuleName Patchouli Write-Host {} -ParameterFilter { $Object -match "file\d.patch" }
            Mock -ModuleName Patchouli Test-FzfAvailability { return $false }
            Mock -ModuleName Patchouli Select-ByIndex { return "file1.patch" }
            Mock -ModuleName Patchouli Read-Host { return 0 }
            Mock -ModuleName Patchouli Get-ChildItem { return @([PSCustomObject]@{ FullName = "file1.patch" } , [PSCustomObject]@{ FullName = "file2.patch" } ) } -ParameterFilter { $Filter -eq "*.patch" }
        }
        BeforeEach { Select-PatchFile }
        Context "Demande un index" {
            It "Selectionne par index"          { Assert-MockCalled -ModuleName Patchouli Select-ByIndex -Exactly 1 }
            It "Affiche les patchs disponibles" { Assert-MockCalled -ModuleName Patchouli Write-Host -Exactly 2 }
            It "Lit l'index fourni par l'utilisateur" { Assert-MockCalled -ModuleName Patchouli Read-Host -Exactly 1 }
        }
        Context "Demande tous les patchs" {
            BeforeAll { Mock -ModuleName Patchouli Read-Host { return 'a' } }
            It "Retourne tous les patchs" { Assert-MockCalled -ModuleName Patchouli Select-ByIndex -ParameterFilter { $All -eq $true } -Exactly 1 }
        }
    }
}

Describe "Recuperer les diff" {
    Context "Il y a deux fichiers modifies" {
    BeforeAll { Mock -ModuleName Patchouli git { return @("file1", "file2" ) } }
        It "Fait appel a git diff" {
            Show-PatchDifferenceSummary
            Assert-MockCalled -ModuleName Patchouli git -Exactly 1
        }
        It "Retourne les fichiers modifies" { Show-PatchDifferenceSummary | Should -Be @("file1", "file2") } 
    }
    Context "Il n'y a pas de fichier modifie" {
        BeforeAll { Mock -ModuleName Patchouli git { return @() } }
        It "Retourne un tableau vide" { Show-PatchDifferenceSummary | Should -BeNullOrEmpty }
    }
}


Describe "Creer un patch" {
    Context "Si fzf est disponible" {
        BeforeAll { 
            Mock -ModuleName Patchouli New-Configuration        { return @{ Patchs = @([PSCustomObject]@{ FullName = "file1.patch" }) } }
            Mock -ModuleName Patchouli Show-DifferenceSummary   { return @("file1.patch") } 
            Mock -ModuleName Patchouli Select-WithFzf           { return "file1.patch"    }
            Mock -ModuleName Patchouli Test-Path                { return $true            } -ParameterFilter { $Path -eq "file1.patch" }
            Mock -ModuleName Patchouli Out-Difference
        }
        Context "Lorsque Fzf est disponible" {
            BeforeAll { 
                Mock -ModuleName Patchouli Test-FzfAvailability { return $true          } 
                Mock -ModuleName Patchouli Select-WithFzf       { return "file1.patch"  }
            }
            BeforeEach { New-PatchDiff }
            It "Fait appel a git diff" { Assert-MockCalled -ModuleName Patchouli Show-DifferenceSummary -Exactly 1 }
            It "Selectionne le patch"  { Assert-MockCalled -ModuleName Patchouli Select-WithFzf         -Exactly 1 }
            It "Ecrit le patch"        { Assert-MockCalled -ModuleName Patchouli Out-Difference         -Exactly 1 }
        }
        Context "Lorsque Fzf n'est pas disponible" {
            BeforeAll { Mock -ModuleName Patchouli Test-FzfAvailability { return $false } }
        }
    }
}

Describe "Applique un patch" -skip {

}

Describe "Supprime un patch" -skip {

}

Describe "Actualise un patch" -skip {

}

