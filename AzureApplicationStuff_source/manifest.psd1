@{
    RootModule        = 'TestModule.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = '4f3be463-5338-4351-b7f2-0daf4d1c77d3'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions focused on application accounts. More details at https://doitpsway.com/series/azure.
Some of the interesting functions:
- Add-AzureAppUserConsent
- Get-AzureAppConsentRequest
- Get-AzureAppVerificationStatus
- Get-AzureServicePrincipalBySecurityAttribute
- Get-AzureServicePrincipalPermissions
- Grant-AzureServicePrincipalPermission
- Remove-AzureAppUserConsent
- Revoke-AzureServicePrincipalPermission
- Set-AzureAppCertificate
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @('Az.Accounts', 'MSGraphStuff', 'Microsoft.Graph.Applications', 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Beta.Applications', 'Microsoft.Graph.DirectoryObjects', 'Microsoft.Graph.Groups', 'Microsoft.Graph.Identity.SignIns', 'Microsoft.Graph.Users', 'AzureCommonStuff', 'AzureOtherStuff')
    FunctionsToExport = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Azure', 'AzureApplicationStuff', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            1.0.1
                FIXES
                    Get-AzureEnterpriseApplication
            1.1.0
                BREAKING CHANGE
                    Set-AzureAppCertificate - AppId instead of ObjectId
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}