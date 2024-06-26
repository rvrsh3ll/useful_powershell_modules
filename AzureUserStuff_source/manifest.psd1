@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.2'
    GUID              = '836de826-6521-48dd-b63b-98f27786f278'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on user accounts. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Get-AzureAuthenticatorLastUsedDate
- Get-AzureCompletedMFAPrompt
- Get-AzureSkuAssignment
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @('MSGraphStuff', 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Beta.Identity.SignIns', 'Microsoft.Graph.Beta.Reports', 'Microsoft.Graph.Beta.Users', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Users', 'Microsoft.Graph.Users.Actions')
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
                REMOVED
                    Get-AzureUserAuthMethodChanges
            1.0.2
                Added Core PSH support to the module manifest
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}