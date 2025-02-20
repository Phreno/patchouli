BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force
}

Describe "La configuration du patch" {
    It "Recupere un objet de configuration" { New-PatchConfiguration | Should -BeOfType HashTable }
    Describe "La propriete Patchs" {
        Context "Le repository git contient des patchs" {
            BeforeEach { 
                Mock -ModuleName Patchouli Get-ChildItem {
                    return @(
                        [PSCustomObject]@{ Name = "file1.patch" },
                        [PSCustomObject]@{ Name = "file2.patch" }
                    )
                } -ParameterFilter { $Filter -eq "*.patch" }
            }
            It "Recupere les patchs du repository git" { 
                $result = New-PatchConfiguration
                $result.Patchs.Count | Should -Be 2
                $result.Patchs[0].Name | Should -Be "file1.patch"
            }
        }

        Context "Le repository git ne contient pas de patchs" {
            BeforeEach { Mock -ModuleName Patchouli Get-ChildItem { return @() } -ParameterFilter { $Filter -eq "*.patch" } }
            It "Retourne un tableau vide" { (New-PatchConfiguration).Patchs | Should -BeNullOrEmpty }
        }
    }
    Describe "La propriete Repository" {
        Context "Le repository git est valide" {
            BeforeEach { Mock -ModuleName Patchouli Test-Path { return $true } }
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
            Mock -ModuleName Patchouli New-Configuration { return @{ Patchs = @([PSCustomObject]@{ FullName = "file1.patch" }) } }
            Mock -ModuleName Patchouli Select-Object { return "file1.patch" } -ParameterFilter { $ExpandProperty -eq "FullName" }
            Mock -ModuleName Patchouli fzf { return "file1.patch" }
        }
        It "Selectionne avec fzf" {
            Select-PatchWithFzf
            Assert-MockCalled -ModuleName Patchouli fzf -Exactly 1
        }
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
        BeforeEach {
            Mock -ModuleName Patchouli Test-FzfAvailability { return $true }
            Mock -ModuleName Patchouli Select-WithFzf { return "file1.patch" }
        }
        It "Selectionne avec fzf" {
            Select-PatchFile
            Assert-MockCalled -ModuleName Patchouli Select-WithFzf -Exactly 1
        }
    }
    Context "Si fzf n'est pas disponible" {
        BeforeEach {
            Mock -ModuleName Patchouli Write-Host {} -ParameterFilter { $Object -match "file\d.patch" }
            Mock -ModuleName Patchouli Test-FzfAvailability { return $false }
            Mock -ModuleName Patchouli Select-ByIndex { return "file1.patch" }
            Mock -ModuleName Patchouli Read-Host { return 0 }
            Mock -ModuleName Patchouli Get-ChildItem { return @([PSCustomObject]@{ FullName = "file1.patch" } , [PSCustomObject]@{ FullName = "file2.patch" } ) } -ParameterFilter { $Filter -eq "*.patch" }
        }
        It "Selectionne par index" {
            Select-PatchFile
            Assert-MockCalled -ModuleName Patchouli Select-ByIndex -Exactly 1
        }
        It "Affiche les patchs disponibles" {
            Select-PatchFile
            Assert-MockCalled -ModuleName Patchouli Write-Host -Exactly 2
        }
        Context "Demande un index" {
            It "Lit l'index fourni par l'utilisateur" {
                Select-PatchFile
                Assert-MockCalled -ModuleName Patchouli Read-Host -Exactly 1
            }
        }
        Context "Annule la selection" {
            BeforeEach { Mock -ModuleName Patchouli Read-Host { return 'q' } }
            It "Retourne un tableau vide" { Select-PatchFile | Should -BeNullOrEmpty }
        }
        Context "Demande tous les patchs" {
            BeforeEach { Mock -ModuleName Patchouli Read-Host { return 'a' } }
            It "Retourne tous les patchs" {
                Select-PatchFile
                Assert-MockCalled -ModuleName Patchouli Select-ByIndex -ParameterFilter { $All -eq $true } -Exactly 1
            }

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
            Mock -ModuleName Patchouli New-Configuration { return @{ Patchs = @([PSCustomObject]@{ FullName = "file1.patch" }) } }
            Mock -ModuleName Patchouli Show-DifferenceSummary { return @("file1.patch") } 
            Mock -ModuleName Patchouli Select-WithFzf { return "file1.patch" }
            Mock -ModuleName Patchouli Test-Path { return $true } -ParameterFilter { $Path -eq "file1.patch" }
            Mock -ModuleName Patchouli Out-Difference
        }
        Context "Lorsque Fzf est disponible" {
            BeforeAll { 
                Mock -ModuleName Patchouli Test-FzfAvailability { return $true } 
                Mock -ModuleName Patchouli Select-WithFzf { return "file1.patch" }
            }
            It "Fait appel a git diff" {
                New-PatchDiff
                Assert-MockCalled -ModuleName Patchouli Show-DifferenceSummary -Exactly 1
            }
            It "Selectionne le patch" {
                New-PatchDiff
                Assert-MockCalled -ModuleName Patchouli Select-WithFzf -Exactly 1
            }
            It "Ecrit le patch" {
                New-PatchDiff
                Assert-MockCalled -ModuleName Patchouli Out-Difference -Exactly 1
            }
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

