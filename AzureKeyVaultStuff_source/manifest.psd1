@{
    RootModule           = 'TestModule.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '5ac4bd4d-6b1a-49db-ad15-1ed737d89263'
    Author               = '@AndrewZtrhgf'
    CompanyName          = 'Unknown'
    Copyright            = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description          = 'Various Azure KeyVault related functions. More details at https://doitpshway.com/series/azure.
Some of the interesting functions:
- Get-AzureKeyVaultMVSecret - Improved version of the official Get-AzKeyVaultSecret function (supports multiline secrets returned as plaintext PSCredential object)
- Set-AzureKeyVaultMVSecret - Improved version of the official Set-AzKeyVaultSecret function (supports saving multiline secrets (a.k.a. login + password) provided via PSCredential object or as file content)
- ...
'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules      = @('Az.Accounts', 'Az.KeyVault')
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Azure', 'AzureKeyVaultStuff', 'KeyVault')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release.
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}