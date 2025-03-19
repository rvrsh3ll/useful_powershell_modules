#
# Module manifest for module 'AzureARCStuff'
#
# Generated by: @AndrewZtrhgf
#
# Generated on: 19.03.2025
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AzureARCStuff.psm1'

# Version number of this module.
ModuleVersion = '1.0.4'

# Supported PSEditions
CompatiblePSEditions = 'Core'

# ID used to uniquely identify this module
GUID = '37b7cbe4-a986-4fc4-9d6b-6d04dc877ef2'

# Author of this module
Author = '@AndrewZtrhgf'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2022 @AndrewZtrhgf. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Various Azure ARC related functions. More details at https://doitpshway.com/series/azure.
Some of the interesting functions:
- Copy-ToArcMachine - copy file(s) to ARC machine via arc-ssh-proxy
- Enter-ArcPSSession - Enter interactive remote session to ARC machine via arc-ssh-proxy
- Get-ARCExtensionOverview - Returns overview of all installed ARC extensions
- Get-ArcMachineOverview - Get list of all ARC machines in your Azure tenant
- Invoke-ArcCommand - Invoke-Command like alternative via arc-ssh-proxy
- Invoke-ArcRDP - RDP to ARC machine via arc-ssh-proxy
- New-ArcPSSession - Create remote session to ARC machine via arc-ssh-proxy
- ...
'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('Az.Accounts', 
               'Az.ResourceGraph', 
               'AzureKeyVaultStuff', 
               'Az.KeyVault', 
               'Az.Ssh', 
               'Az.Compute', 
               'Microsoft.Graph.Applications')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Copy-ToArcMachine', 'Enter-ArcPSSession', 
               'Get-ARCExtensionAvailableVersion', 'Get-ARCExtensionOverview', 
               'Get-ArcMachineOverview', 'Invoke-ArcCommand', 'Invoke-ArcRDP', 
               'New-ArcPSSession'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Azure','AzureARCStuff','PowerShell','ARC'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/ztrhgf/useful_powershell_modules'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
            1.0.4
                CHANGED
                    Copy-ToArcMachine - can be run against multiple devices now
                    Invoke-ArcRDP - cleanup wait time increased to 10s
                    Invoke-ArcCommand - added parameter machineType to match New-ArcPSSession
                    Enter-ArcPSSession - added parameter machineType to match New-ArcPSSession
            1.0.3
                CHANGED
                    New-ArcPSSession - fixes; better private key file handling; added relay data cleanup
            1.0.2
                ADDED
                    Invoke-ArcCommand
                CHANGED
                    Copy-ToArcMachine - session creation logic moved to New-ArcPSSession
                    Enter-ArcPSSession - session creation logic moved to New-ArcPSSession
                    New-ArcPSSession - option to create multiple sessions at one
                    Invoke-ArcRDP - cleanup wait time increased to 7 seconds
                    Get-ArcMachineOverview - added SMI to the overview
            1.0.1
                ADDED
                    Copy-ToArcMachine
                CHANGED
                    New-ArcPSSession - renamed parameter keyFile to privateKeyFile; session reuse; unnecessary checks removal
                    Enter-ArcPSSession - session reuse; unnecessary checks removal
                    Invoke-ArcRDP - unnecessary checks removal
            1.0.0
                Initial release.
            '

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

