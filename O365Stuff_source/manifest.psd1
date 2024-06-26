@{
    RootModule        = 'O365Stuff.psm1'
    ModuleVersion     = '2.0.1'
    GUID              = '1f9e4f50-2cac-411b-80f8-16003b8a5542'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Office 365 related functions. Some of them are explained at https://doitpsway.com/series/o365.

Some of the interesting functions:
Remove-O365OrphanedMailbox - fixes problem of the orphaned mailboxes
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @("Pnp.PowerShell", "AzureCommonStuff", "ExchangeOnlineManagement", 'Microsoft.Graph.Authentication','Microsoft.Graph.Users','Microsoft.Graph.Identity.DirectoryManagement')
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('O365', 'Office365', 'ExchangeOnline', 'PowerShell')
            ProjectUri = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.2
                Rewrite for using Graph Api instead of deprecated AzureAD and MSOnline modules.
            2.0.1
                Added Core PSH support to the module manifest
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}