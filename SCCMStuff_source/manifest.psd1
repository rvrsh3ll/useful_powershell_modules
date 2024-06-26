@{
    RootModule        = 'SCCMStuff.psm1'
    ModuleVersion     = '1.0.4'
    GUID              = '1f9e4f50-2cac-411b-80f8-16003b8a5542'
    Author            = '@AndrewZtrhgf'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description       = 'Various Azure related functions. Some of them are explained at https://doitpsway.com/series/sccm-mdt-intune.

Some of the interesting functions:
- Add-CMDeviceToCollection - add selected device to selected collection
- Clear-CMClientCache - clear SCCM client cache
- Connect-SCCM - make remote session to SCCM server
- Get-CMLog - open the correct SCCM client/server log(s) based on specified topic
- Invoke-CMAdminServiceQuery - invoke query against SCCM Admin Service
- Invoke-CMAppInstall - invoke installation of deployed application(s) on the client
- Invoke-CMComplianceEvaluation - invoke of compliance validations
- Refresh-CMCollection - refresh SCCM collection members
- Update-CMAppSourceContent - update source data of the application
- Update-CMClientPolicy - update of SCCM client policies (like gpupdate for GPO)
- Get-CMAutopilotHash - read client Autopilot hash from SCCM database
- ...
'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules   = @("CommonStuff", "PowerHTML")
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags       = @('MEMCM', 'PowerShell', 'SCCM')
            ProjectUri = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.4
                Added Core PSH support to the module manifest
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}