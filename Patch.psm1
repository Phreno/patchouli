function New-Configuration {
    Param($Repository="./")
    @{ Repository = ($Repository | Get-Item) }
}

