@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = 'c67c00e7-b329-4f5a-97bd-bdf15ff2f106'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on device accounts. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Get-AzureDeviceWithoutBitlockerKey
- Get-BitlockerEscrowStatusForAzureADDevices
- Set-AzureDeviceExtensionAttribute
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Identity.DirectoryManagement')
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Runbook')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            1.0.1
                CHANGED
                    Get-BitlockerEscrowStatusForAzureADDevices - better uploaded blk key detection
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}