@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.2'
    GUID              = '9520619d-f6f2-4708-bb92-b7ee15391433'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on group accounts. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Get-AzureGroupMemberRecursive - gets group members rerursive, supports various filtering options like skip disabled accounts etc
- Get-AzureGroupSettings - official Get-MgGroup -Property Settings doesn`t return anything for some reason
- Set-AzureRingGroup - function for dynamically setting members of specified "ring" groups based on the provided users list (members of the "rootGroup") and the members per group percent ratio ("ringGroupConfig").
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @('MSGraphStuff', 'Microsoft.Graph.Authentication', 'Microsoft.Graph.DirectoryObjects', 'Microsoft.Graph.Groups')
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'AzureGroupStuff', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Runbook')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            1.0.1
                FIXES
                    Get-AzureGroupMemberRecursive - skip duplicities, passing incorrect parameters when called recursive upon group objects
            1.0.2
                Added Core PSH support to the module manifest
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}