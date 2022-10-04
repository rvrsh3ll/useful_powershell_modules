@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.0.14'
    GUID              = '1f9e4f50-2cac-411b-80f8-16003b8a5542'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions. Some of them are explained at https://doitpsway.com.

Some of the interesting functions:
- Add-AzureADAppUserConsent - granting permission consent on behalf of another user
- Add-AzureADAppCertificate - add the auth. certificate (existing or create self-signed) to selected Azure application as an secret
- Get-AzureADAccountOccurrence - for getting all occurrences of specified account in your Azure environment
- Get-AzureADAppVerificationStatus - get Azure app publisher verification status
- Get-AzureADAppConsentRequest - for getting all application admin consent requests
- Get-AzureADDeviceMembership - similar to Get-AzureADUserMembership, but for devices
- Get-AzureDevOpsOrganizationOverview - list of all DevOps organizations
- Remove-AzureADAccountOccurrence - remove specified account from various Azure environment sections and optionally replace it with other user and inform him. Can be used in conjunction with Get-AzureADAccountOccurrence.
- Remove-AzureADAppUserConsent - removes user consent
- ...

Some of the authentication-related functions:
- Connect-AzureAD2 - smarter version of Connect-AzureAD that can reuse existing session and more
- New-AzureDevOpsAuthHeader
- New-GraphAPIAuthHeader
'
    PowerShellVersion = '5.1'
    RequiredModules   = @('AzureAD', 'Az.Accounts', 'Az.Resources', 'MSAL.PS', 'PnP.PowerShell', 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Users', 'Microsoft.Graph.Identity.SignIns')
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('Azure', 'PowerShell', 'Monitoring', 'Audit', 'Security')
            ProjectUri = 'https://doitpsway.com/series/azure'
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}