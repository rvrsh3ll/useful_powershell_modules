@{
    RootModule           = 'TestModule.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '37b7cbe4-a986-4fc4-9d6b-6d04dc877ef2'
    Author               = '@AndrewZtrhgf'
    CompanyName          = 'Unknown'
    Copyright            = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description          = 'Various Azure ARC related functions. More details at https://doitpshway.com/series/azure.
Some of the interesting functions:
- Enter-ArcPSSession - Enter interactive remote session to ARC machine via arc-ssh-proxy
- Get-ARCExtensionOverview - Returns overview of all installed ARC extensions
- Get-ArcMachineOverview - Get list of all ARC machines in your Azure tenant
- Invoke-ArcRDP - RDP to ARC machine via arc-ssh-proxy
- New-ArcPSSession - Enter interactive remote session to ARC machine via arc-ssh-proxy
- ...
'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = 'Core'
    RequiredModules      = @('Az.Accounts', 'Az.ResourceGraph', 'AzureKeyVaultStuff', 'Az.KeyVault', 'Az.Ssh', 'Az.Compute', 'Microsoft.Graph.Applications')
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Azure', 'AzureARCStuff', 'PowerShell', 'ARC')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release.
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}