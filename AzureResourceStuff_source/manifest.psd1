@{
    RootModule           = 'AzureResourceStuff.psm1'
    ModuleVersion        = '1.0.14'
    GUID                 = '6f9132bb-ec13-43d9-86ea-2bba4017e71e'
    Author               = '@AndrewZtrhgf'
    CompanyName          = 'Unknown'
    Copyright            = '(c) 2022 @AndrewZtrhgf. All rights reserved.'
    Description          = 'Various Azure related functions focused on resources. More details at https://doitpshway.com/series/azure.
Some of the interesting functions:
- Export-VariableToStorage - save PowerShell variable as XML file in Azure Blob storage
- Get-AzureResource - return resources for all or just selected Azure subscription(s)
- Get-AutomationVariable2 - get Automation variable and convert it from CliXml string back to PS object
- Import-VariableFromStorage - download Azure Blob storage XML file and convert it back to the original PowerShell variable
- New-AzureAutomationModule - import new (or update existing) Azure Automation PSH module (including its dependencies)
- Set-AutomationVariable2 - save object as CliXml string to selected Automation variable
- Update-AzureAutomationModule

- functions covering whole life-cycle of Azure Automation Account (with focus on Custom Runtime feature)
    - create/set/remove/copy runtime, import/replace/remove module (custom or default ones, from PSHGallery or as a zip file)
- ...
'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = 'Core', 'Desktop'
    RequiredModules      = @('Az.Accounts', 'Az.Automation', 'Az.Resources', 'Az.Storage', 'CommonStuff')
    FunctionsToExport    = @()
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Azure', 'AzureResourceStuff', 'PowerShell', 'Monitoring', 'Audit', 'Security', 'Graph', 'Automation', 'Runbook', 'Runtime', 'Resource')
            ProjectUri   = 'https://github.com/ztrhgf/useful_powershell_modules'
            ReleaseNotes = '
            1.0.0
                Initial release. Some functions are migrated from now deprecated AzureADStuff module, some are completely new.
            1.0.1
                CHANGED
                New-AzureAutomationModule - added support for prerelease modules
            1.0.2
                CHANGED
                New-AzureAutomationModule - removed support for 7.1 runtime because official Az commands don''t support it either
                ADDED
                    Update-AzureAutomationModule
            1.0.3
                ADDED
                    Export-VariableToStorage
                    Import-VariableFromStorage
            1.0.4
                ADDED
                    Get-AutomationVariable2
                    Set-AutomationVariable2
            1.0.5
                CHANGED
                    Added Core PSH support to the module manifest
            1.0.6
                CHANGED
                    Comments
                    URL in module manifest description
            1.0.7
                ADDED
                    Get-AzureAutomationRunbookRuntime
                    Get-AzureAutomationRuntime
                    Get-AzureAutomationRuntimeAvailableDefaultModule
                    Get-AzureAutomationRuntimeCustomModule
                    Get-AzureAutomationRuntimeSelectedDefaultModule
                    New-AzureAutomationGraphToken
                    New-AzureAutomationRuntime
                    Remove-AzureAutomationRuntime
                    Remove-AzureAutomationRuntimeModule
                    Set-AzureAutomationRuntimeDefaultModule
                    Set-AzureAutomationRuntimeDescription
                    Set-AzureAutomationRuntimeModule
                    Set-AzureAutomationRunbookRuntime
            1.0.8
                CHANGED
                    Set-AzureAutomationRuntimeModule renamed to New-AzureAutomationRuntimeModule, added support for autoamtic adding module dependencies
                ADDED
                    Set-AzureAutomationModule alias for New-AzureAutomationModule
            1.0.9
                FIXED
                    module dependencies now contains CommonStuff module (because of Invoke-RestMethod2)

                    New-AzureAutomationModule, New-AzureAutomationRuntimeModule - better process dependencies with specified minimum/maximum version

                    New-AzureAutomationRuntime - better existing runtime detection
                ADDED
                    Copy-AzureAutomationRuntime
                    Update-AzureAutomationRunbookModule
            1.0.10
                FIXED
                    Update-AzureAutomationModule, Update-AzureAutomationRunbookModule, New-AzureAutomationRuntimeModule
            1.0.11
                ADDED
                    Get-AzureAutomationRunbookTestJobOutput
                    Get-AzureAutomationRunbookTestJobStatus
                    Invoke-AzureAutomationRunbookTestJob
                    Stop-AzureAutomationRunbookTestJob
            1.0.12
                ADDED
                    Get-AzureAutomationRunbookContent
                    Start-AzureAutomationRunbookTestJob
                    New-AzureAutomationRuntimeZIPModule
                    Set-AzureAutomationRunbookContent

                FIXED
                    Get-AzureAutomationRunbookTestJobOutput
                    Set-AzureAutomationRuntimeDefaultModule

                CHANGED
                    Get-AzureAutomationRuntimeCustomModule - added simplified parameter
                    Get-AzureAutomationRuntimeSelectedDefaultModule - changed the output
                    New-AzureAutomationRuntimeModule - added dontWait parameter

                REMOVED
                    Invoke-AzureAutomationRunbookTestJob
            1.0.13
                CHANGED
                    Update-AzureAutomationRunbookModule - new "safely" parameter
                    New-AzureAutomationGraphToken - support for Az 5.x (SecureString returned by Get-AzAccessToken)
                    Set-AzureAutomationRunbookContent - better header handling
                    Get-AzureAutomationRunbookContent - better header handling
                    New-AzureAutomationRuntimeZIPModule - better header handling
                    New-AzureAutomationRuntime - parameter "runtimeVersion" is mandatory

                    Hide warning message when calling Get-AzAccessToken in most functions.
            1.0.14
                FIXED
                    New-AzureAutomationRuntimeZIPModule - retrieval of the upload url (changed in the Azure backend)
            '
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}