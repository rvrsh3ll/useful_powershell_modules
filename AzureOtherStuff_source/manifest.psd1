@{
    RootModule           = 'TestModule.psm1'
    ModuleVersion        = '1.0.3'
    GUID                 = 'a0ef14ff-c5d6-47e9-a431-ffb512637245'
    Author               = '@AndrewZtrhgf'
    CompanyName          = 'Unknown'
    Copyright            = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description          = 'Various Azure related functions. More details at https://doitpshway.com/series/azure.
Some of the interesting functions:
- Get-AzureAuditAggregatedSignInEvent - gets aggregated types of Azure sign-in logs: User sign-ins (non-interactive), Service principal sign-ins, Managed identity sign-ins
- Get-AzureAuditSignInEvent - proxy function for Get-MgBetaAuditLogSignIn that simplifies result filtering
- Get-AzureAssessNotificationEmail
- Get-AzureDevOpsOrganizationOverview
- Open-AzureAdminConsentPage
- ...
'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules      = @('Az.Accounts', 'MSGraphStuff', 'AzureCommonStuff')
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Runbook')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            1.0.1
                ADDED
                    Get-AzureAuditSignInEvent
                    Get-AzureAuditAggregatedSignInEvent
            1.0.2
                CHANGED
                    Get-AzureAuditAggregatedSignInEvent - get rid of Microsoft.Graph.Intune module
                    Get-AzureAuditSignInEvent - by default gets any event type
            1.0.3
                CHANGED
                    Get-AzureDevOpsOrganizationOverview - fixes
                    Get-AzureAuditSignInEvent - added support for multiple ids
                    Get-AzureAuditAggregatedSignInEvent - support for Az 5.x (SecureString returned by Get-AzAccessToken)
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}