BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psd1') -Force

    function Get-DummyFileName {
        param($index = 0, [switch]$fullName)
        if ($fullName) { "/fullname/file$index.patch" }
        else { "file$index.patch" }
    }

    function New-FileNameMock {
        param(
            $count = 1,
            [switch] $FullName
        )
        for ($i = 0; $i -lt $count; $i++) {
            if ($FullName) { "/fullname/$(Get-DummyFileName -index $i)" }
            else { Get-DummyFileName -index $i } 
        }
    }

    function New-FileMock {
        param($count = 1)
        for ($i = 0; $i -lt $count; $i++) { [PSCustomObject]@{ Name = Get-DummyFileName -index $i; FullName = Get-DummyFileName -index $i -FullName } }
    }

    function New-ConfigurationMock {
        param($count = 1)
        [PSCustomObject]@{ Patchs = New-FileMock -Count $count }
    }

}

Describe "La configuration du patch" {
    It "Recupere un objet de configuration" { New-PatchConfiguration | Should -BeOfType HashTable }
    Describe "La propriete Patchs" {
        Context "Le repository git contient des patchs" {
            BeforeAll { Mock -ModuleName Patchouli Get-ChildItem { return New-FileMock -Count 2 } -ParameterFilter { $Filter -eq "*.patch" } }
            BeforeEach { $result = New-PatchConfiguration }
            It "Recupere les patchs du repository git" { $result.Patchs.Count | Should -Be 2 }
            It "Recupere le nom des fichiers patchs" {$result.Patchs[0].Name | Should -Be "file0.patch" }
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
            It "Retourne le repository git cible" { (New-PatchConfiguration).Repository | Should -BeOfType System.IO.DirectoryInfo }
            It "Permet la Modification du repository git cible" {
                (New-PatchConfiguration -Repository "./").Repository.BaseName | Should -Be patchouli
                (New-PatchConfiguration -Repository "../").Repository.BaseName | Should -Not -Be patchouli 
            }
        }
        Context "Le repository git est invalide" {
            It "Intercepte une erreur" { { New-PatchConfiguration -Repository "/this/directory/does/not/exists" } | Should -Throw }
        }
    }
}

Describe "La selection avec fzf" {
    Context "Si fzf est disponible" {
        BeforeAll { Mock -ModuleName Patchouli fzf { Get-DummyFileName -Index 1    } }
        BeforeEach { Select-PatchWithFzf }
        It "Selectionne avec fzf" { Assert-MockCalled -ModuleName Patchouli fzf -Exactly 1 }
    }
}

Describe "La selection par index" {
    Context "Un id peut etre utilise" {
        It "Retourne le patch par defaut si aucun index n'est disponible" { Select-PatchByIndex -Paths (New-FileNameMock -Count 2)           | Should -Be "file0.patch" }
        It "Retourne le premier patch par index"                          { Select-PatchByIndex -Paths (New-FileNameMock -Count 2) -Index 0  | Should -Be "file0.patch" }
        It "Retourne le second patch par index"                           { Select-PatchByIndex -Paths (New-FileNameMock -Count 2) -Index 1  | Should -Be "file1.patch" }
    }
    Context "Tous les patchs peuvent etre selectionnes" {
        It "Retourne tous les patchs" { Select-PatchByIndex -All -Paths (New-FileNameMock -Count 2) | Should -Be @("file0.patch", "file1.patch") }
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
            Mock -ModuleName Patchouli Write-Host           {                       } -ParameterFilter { $Object -match "file\d.patch" }
            Mock -ModuleName Patchouli Test-FzfAvailability { return $false         }
            Mock -ModuleName Patchouli Select-ByIndex       { return "file1.patch"  }
            Mock -ModuleName Patchouli Read-Host            { return 0              }
            Mock -ModuleName Patchouli Get-ChildItem        { New-FileMock -Count 2 } -ParameterFilter { $Filter -eq "*.patch" }
        }
        BeforeEach { Select-PatchFile }
        Context "Demande un index" {
            It "Selectionne par index"                { Assert-MockCalled -ModuleName Patchouli Select-ByIndex -Exactly 1 }
            It "Affiche les patchs disponibles"       { Assert-MockCalled -ModuleName Patchouli Write-Host     -Exactly 2 }
            It "Lit l'index fourni par l'utilisateur" { Assert-MockCalled -ModuleName Patchouli Read-Host      -Exactly 1 }
        }
        Context "Demande tous les patchs" {
            BeforeAll { Mock -ModuleName Patchouli Read-Host { return 'a' } }
            It "Retourne tous les patchs" { Assert-MockCalled -ModuleName Patchouli Select-ByIndex -ParameterFilter { $All -eq $true } -Exactly 1 }
        }
    }
}

Describe "Recuperer les diff" {
    Context "Il y a deux fichiers modifies" {
    BeforeAll { Mock -ModuleName Patchouli git { New-FileNameMock -Count 2 } }
        It "Fait appel a git diff" {
            Show-PatchDifferenceSummary
            Assert-MockCalled -ModuleName Patchouli git -Exactly 1
        }
        It "Retourne les fichiers modifies" { Show-PatchDifferenceSummary | Should -Be @("file0.patch", "file1.patch") } 
    }
    Context "Il n'y a pas de fichier modifie" {
        BeforeAll { Mock -ModuleName Patchouli git { return @() } }
        It "Retourne un tableau vide" { Show-PatchDifferenceSummary | Should -BeNullOrEmpty }
    }
}


Describe "Creer un patch" {
    BeforeAll { 
        Mock -ModuleName Patchouli New-Configuration        { New-ConfigurationMock -Count 2 }
        Mock -ModuleName Patchouli Show-DifferenceSummary   { New-FileMock          -Count 2 } 
        Mock -ModuleName Patchouli Select-File              { Get-DummyFileName     -Index 1 }
        Mock -ModuleName Patchouli Test-Path                {  $true                         } -ParameterFilter { $Path -eq "file1.patch" }
        Mock -ModuleName Patchouli Out-Difference
    }
    BeforeEach { New-PatchDiff }
    # It "Fait appel a git diff" { Assert-MockCalled -ModuleName Patchouli Show-DifferenceSummary -Exactly 1 }
    # It "Selectionne le patch"  { Assert-MockCalled -ModuleName Patchouli Select-WithFzf         -Exactly 1 }
    # It "Ecrit le patch"        { Assert-MockCalled -ModuleName Patchouli Out-Difference         -Exactly 1 }
}

Describe "Applique un patch" -skip {

}

Describe "Supprime un patch" -skip {

}

Describe "Actualise un patch" -skip {

}

