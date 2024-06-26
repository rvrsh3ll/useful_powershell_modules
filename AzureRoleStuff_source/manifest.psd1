@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = 'be5c985a-4f97-4864-9bb2-cac64de6b7a6'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on roles. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Get-AzureRoleAssignments
- Remove-AzureUserMemberOfDirectoryRole
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @('Az.Accounts', 'Az.Resources', 'AzureCommonStuff', 'MSGraphStuff')
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
                Added Core PSH support to the module manifest
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}