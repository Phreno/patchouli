function New-Configuration {
 [CmdletBinding()]
    Param(
    [ValidateScript({ "$_/.git" | Test-Path })]$Repository="./")
    @{
        Repository = ($Repository | Get-Item )
    }
}

