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
Describe "La selection d'un patch" {
    Context "Si fzf est disponible (Mocked)" {
        BeforeAll {
            "test content" | Out-File -FilePath "file1.patch"
            Mock -ModuleName Patchouli Get-ChildItem { return @([PSCustomObject]@{ Name = "file1.patch" }) } -ParameterFilter { $Filter -eq "*.patch" }
            Mock -ModuleName Patchouli fzf { return "file1.patch" }
        }

        It "Permet de selectionner un patch via fzf" {
            $result = Select-PatchFile
            $result | Should -Be "file1.patch"
        }
    }
    Context "Si fzf n'est pas disponible" {
        BeforeAll {
            Mock -ModuleName Patchouli Get-ChildItem { return @([PSCustomObject]@{ Name = "file1.patch" }) } -ParameterFilter { $Filter -eq "*.patch" }
            Mock -ModuleName Patchouli fzf { throw "fzf not found" }
        }
        It "Permet de selectionner un patch via Select-Object" {
            $result = Select-PatchFile
            $result | Should -Be "file1.patch"
        }
    }

}
