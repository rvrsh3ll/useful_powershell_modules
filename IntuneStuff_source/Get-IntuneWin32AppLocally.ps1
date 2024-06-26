﻿function Get-IntuneWin32AppLocally {
    <#
    .SYNOPSIS
    Function for showing Win32 apps deployed from Intune to local/remote computer.

    Apps details are gathered from clients registry (HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps) and Intune log file ($env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log)

    .DESCRIPTION
    Function for showing Win32 apps deployed from Intune to local/remote computer.

    App details are gathered from clients registry (HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps) and Intune log file ($env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log)

    .PARAMETER computerName
    Name of remote computer where you want to get Win32 apps from.

    .PARAMETER getDataFromIntune
    Switch for getting Apps and User names from Intune, so locally used IDs can be translated.
    If you omit this switch, local Intune logs will be searched for such information instead.

    .PARAMETER excludeSystemApp
    Switch for excluding Apps targeted to SYSTEM.

    .EXAMPLE
    Get-IntuneWin32AppLocally

    Get and show Win32App(s) deployed from Intune to local computer.
    IDs of targeted users and apps will be translated using information from local Intune log files.

    .EXAMPLE
    Get-IntuneWin32AppLocally -computerName PC-01 -getDataFromIntune

    Get and show Win32App(s) deployed from Intune to computer PC-01. IDs of apps and targeted users will be translated to corresponding names.

    .EXAMPLE
    $win32AppData = Get-IntuneWin32AppLocally

    $myApp = ($win32AppData | ? DisplayName -eq 'MyApp')

    "Output complete object"
    $myApp

    "Detection script content for application 'MyApp'"
    $myApp.additionalData.DetectionRule.DetectionText.ScriptBody

    "Requirement script content for application 'MyApp'"
    $myApp.additionalData.ExtendedRequirementRules.RequirementText.ScriptBody

    "Install command for application 'MyApp'"
    $myApp.additionalData.InstallCommandLine

    Show various interesting information for 'MyApp' application deployment.
    #>

    [CmdletBinding()]
    param (
        [string] $computerName,

        [switch] $getDataFromIntune,

        [switch] $excludeSystemApp
    )

    if (!$computerName) {
        # access to registry key "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension" now needs admin permission
        if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "Function '$($MyInvocation.MyCommand)' needs to be run with administrator permission"
        }
    }

    #region helper function
    # function translates user Azure ID or SID to its display name
    function _getTargetName {
        param ([string] $id)

        Write-Verbose "Translating account $id to its name (SID)"

        if (!$id) {
            Write-Verbose "Id was null"
            return
        } elseif ($id -eq 'device') {
            # xml nodes contains 'device' instead of 'Device'
            return 'Device'
        }

        $errPref = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        try {
            if ($id -eq '00000000-0000-0000-0000-000000000000' -or $id -eq 'S-0-0-00-0000000000-0000000000-000000000-000') {
                Write-Verbose "`t- Id belongs to device"
                return 'Device'
            } elseif ($id -match "^S-\d+-\d+-\d+") {
                # it is local account
                Write-Verbose "`t- Id is SID, trying to translate to local account name"
                return ((New-Object System.Security.Principal.SecurityIdentifier($id)).Translate([System.Security.Principal.NTAccount])).Value
            } else {
                # it is AzureAD account
                Write-Verbose "`t- Id belongs to AAD account"
                if ($getDataFromIntune) {
                    Write-Verbose "`t- Translating ID using Intune data"
                    return ($intuneUser | ? id -EQ $id).userPrincipalName
                } else {
                    Write-Verbose "`t- Getting SID that belongs to AAD ID, by searching Intune logs"
                    $userSID = Get-UserSIDForUserAzureID $id
                    if ($userSID) {
                        _getTargetName $userSID
                    } else {
                        return $id
                    }
                }
            }
        } catch {
            Write-Warning "Unable to translate $id to account name ($_)"
            $ErrorActionPreference = $errPref
            return $id
        }
    }

    # function for translating error codes to error messages
    function Get-Win32AppErrMsg {
        param (
            [string] $errorCode
        )

        if (!$errorCode -or $errorCode -eq 0) { return }

        # https://docs.microsoft.com/en-us/troubleshoot/mem/intune/app-install-error-codes
        $errorCodeList = @{
            "-942583883"  = "The app failed to install."
            "-942583878"  = "The app installation was canceled because the installation (APK) file was deleted after download, but before installation."
            "-942583877"  = "The app installation was canceled because the process was restarted during installation."
            "-2016345060" = "The application was not detected after installation completed successfully."
            "-942583886"  = "The download failed because of an unknown error."
            "-942583688"  = "The download failed because of an unknown error. The policy will be retried the next time the device syncs."
            "-942583887"  = "The end user canceled the app installation."
            "-942583787"  = "The file download process was unexpectedly stopped."
            "-942583684"  = "The file download service was unexpectedly stopped. The policy will be retried the next time the device syncs."
            "-942583880"  = "The app failed to uninstall."
            "-942583881"  = "The app installation APK file used for the upgrade does not match the signature for the current app on the device."
            "-942583879"  = "The end user canceled the app installation."
            "-942583876"  = "Uninstall of the app was canceled because the process was restarted during installation."
            "-942583882"  = "The app installation APK file cannot be installed because it was not signed."
            "-2016335610" = "Apple MDM Agent error: App installation command failed with no error reason specified. Retry app installation."
            "-2016333508" = "Network connection on the client was lost or interrupted. Later attempts should succeed in a better network environment."
            "-2016333507" = "Could not retrieve license for the app with iTunes Store ID"
            "-2016341112" = "iOS/iPadOS device is currently busy."
            "-2016330908" = "The app installation has failed."
            "-2016330906" = "The app is managed, but has expired or been removed by the user."
            "-2016330912" = "The app is scheduled for installation, but needs a redemption code to complete the transaction."
            "-2016330883" = "Unknown error."
            "-2016330910" = "The user rejected the offer to install the app."
            "-2016330909" = "The user rejected the offer to update the app."
            "-2016345112" = "Unknown error"
            "-2016330861" = "Can only install VPP apps on Shared iPad."
            "-2016330860" = "Can't install apps when App Store is disabled."
            "-2016330859" = "Can't find VPP license for app."
            "-2016330858" = "Can't install system apps with your MDM provider."
            "-2016330857" = "Can't install apps when device is in Lost Mode."
            "-2016330856" = "Can't install apps when device is in kiosk mode."
            "-2016330852" = "Can't install 32-bit apps on this device."
            "-2016330855" = "User must sign in to the App Store."
            "-2016330854" = "Unknown problem. Please try again."
            "-2016330853" = "The app installation failed. Intune will try again the next time the device syncs."
            "-2016330882" = "License Assignment failed with Apple error 'No VPP licenses remaining'"
            "-2016330898" = "App Install Failure 12024: Unknown cause."
            "-2016330881" = "Needed app configuration policy not present, ensure policy is targeted to same groups."
            "-2016330903" = "Device VPP licensing is only applicable for iOS/iPadOS 9.0+ devices."
            "-2016330865" = "The application is installed on the device but is unmanaged."
            "-2016330904" = "User declined app management"
            "-2016335971" = "Unknown error."
            "-2016330851" = "The latest version of the app failed to update from an earlier version."
            "-2016330897" = "Your connection to Intune timed out."
            "-2016330896" = "You lost connection to the Internet."
            "-2016330894" = "You lost connection to the Internet."
            "-2016330893" = "You lost connection to the Internet."
            "-2016330889" = "The secure connection failed."
            "-2016330880" = "CannotConnectToITunesStoreError"
            "-2016330849" = "The VPP App has an update available"
            "2016330850"  = "Can't enforce app uninstall setting. Retry installing the app."
            "-2147009281" = "(client error)"
            "-2133909476" = "(client error)"
            "-2147009296" = "The package is unsigned. The publisher name does not match the signing certificate subject. Check the AppxPackagingOM event log for information. For more information, see Troubleshooting packaging, deployment, and query of Windows Store apps."
            "-2147009285" = "Increment the version number of the app, then rebuild and re-sign the package. Remove the old package for every user on the system before you install the new package. For more information, see Troubleshooting packaging, deployment, and query of Windows Store apps."
        }

        $errorMessage = $errorCodeList.$errorCode
        if (!$errorMessage) {
            $errorMessage = "*unable to translate $errorCode*"
        }

        return $errorMessage
    }

    # create helper functions text definition for usage in remote sessions
    $allFunctionDefs = "function _getTargetName { ${function:_getTargetName} }; function Get-UserSIDForUserAzureID { ${function:Get-UserSIDForUserAzureID} }; function Get-Win32AppErrMsg { ${function:Get-Win32AppErrMsg} }; function Get-IntuneLogWin32AppData { ${function:Get-IntuneLogWin32AppData} }; function Get-IntuneLogWin32AppReportingResultData { ${function:Get-IntuneLogWin32AppReportingResultData} }"
    #endregion helper function

    #region prepare
    if ($getDataFromIntune) {
        if (!(Get-Command Get-MgContext -ErrorAction silentlycontinue) -or !(Get-MgContext)) {
            throw "$($MyInvocation.MyCommand): Authentication needed. Please call Connect-MgGraph."
        }

        Write-Verbose "Getting Intune data"
        # filtering by ID is as slow as getting all data
        # Invoke-MSGraphRequest -Url 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$filter=(id%20eq%20%2756695a77-925a-4df0-be79-24ed039afa86%27)'
        $intuneApp = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?select=id,displayname" | Get-MgGraphAllPages
        $intuneUser = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/beta/users?select=id,userPrincipalName' | Get-MgGraphAllPages
    }

    if ($computerName) {
        $session = New-PSSession -ComputerName $computerName -ErrorAction Stop
    }
    #endregion prepare

    #region get data
    $scriptBlock = {
        param($verbosePref, $excludeSystemApp, $getDataFromIntune, $intuneApp, $intuneUser, $allFunctionDefs)

        # inherit verbose settings from host session
        $VerbosePreference = $verbosePref

        # recreate functions from their text definitions
        . ([ScriptBlock]::Create($allFunctionDefs))

        # get additional data from Intune logs
        Write-Verbose "Getting additional Win32App data from client Intune logs"
        $logData = Get-IntuneLogWin32AppData
        $logReportingData = Get-IntuneLogWin32AppReportingResultData # to be able to translate IDs of apps which don't meet requirements

        $processedWin32AppId = @()

        foreach ($scope in (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps" -ErrorAction SilentlyContinue | ? PSChildName -NotIn "OperationalState", "Reporting")) {
            $userAzureObjectID = Split-Path $scope.Name -Leaf

            if ($excludeSystemApp -and $userAzureObjectID -eq "00000000-0000-0000-0000-000000000000") {
                Write-Verbose "Skipping system deployments"
                continue
            }

            $userWin32AppRoot = $scope.PSPath
            $win32AppIDList = Get-ChildItem $userWin32AppRoot | select -ExpandProperty PSChildName | % { $_ -replace "_\d+$" } | select -Unique | ? { $_ -ne 'GRS' }

            $win32AppIDList | % {
                $win32AppID = $_

                Write-Verbose "Processing App ID $win32AppID"

                $processedWin32AppId += $win32AppID

                #region get Win32App data
                $newestWin32AppRecord = Get-ChildItem $userWin32AppRoot | ? PSChildName -Match ([regex]::escape($win32AppID)) | Sort-Object -Descending -Property PSChildName | select -First 1

                try {
                    $lastUpdatedTimeUtc = $null
                    $lastUpdatedTimeUtc = Get-ItemPropertyValue $newestWin32AppRecord.PSPath -Name LastUpdatedTimeUtc -ErrorAction Stop
                } catch {
                    Write-Verbose "`tUnable to get LastUpdatedTimeUtc data"
                }

                try {
                    $deploymentType = $null
                    $deploymentType = Get-ItemPropertyValue $newestWin32AppRecord.PSPath -Name Intent -ErrorAction Stop
                } catch {
                    Write-Verbose "`tUnable to get Intent data"
                }
                if ($deploymentType) {
                    switch ($deploymentType) {
                        0 { $deploymentType = "Dependency" }
                        1 { $deploymentType = "Available" }
                        3 { $deploymentType = "Required" }
                        4 { $deploymentType = "Uninstall" }
                        default { Write-Error "Undefined deployment type $deploymentType" }
                    }
                }

                try {
                    $complianceStateMessage = $null
                    $complianceStateMessage = Get-ItemPropertyValue "$($newestWin32AppRecord.PSPath)\ComplianceStateMessage" -Name ComplianceStateMessage -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    Write-Verbose "`tUnable to get Compliance State Message data"
                }

                $complianceState = $complianceStateMessage.ComplianceState
                if ($complianceState) {
                    switch ($complianceState) {
                        0 { $complianceState = "Unknown" }
                        1 { $complianceState = "Compliant" }
                        2 { $complianceState = "Not compliant" }
                        3 { $complianceState = "Conflict (Not applicable for app deployment)" }
                        4 { $complianceState = "Error" }
                        5 { $complianceState = "Compliant" }
                        default { Write-Error "Undefined compliance status $complianceState" }
                    }
                }

                $desiredState = $complianceStateMessage.DesiredState
                if ($desiredState) {
                    switch ($desiredState) {
                        0	{ $desiredState = "None" }
                        1	{ $desiredState = "NotPresent" }
                        2	{ $desiredState = "Present" }
                        3	{ $desiredState = "Unknown" }
                        4	{ $desiredState = "Available" }
                        default { Write-Error "Undefined desired status $desiredState" }
                    }
                }

                try {
                    $enforcementStateMessage = $null
                    $enforcementStateMessage = Get-ItemPropertyValue "$($newestWin32AppRecord.PSPath)\EnforcementStateMessage" -Name EnforcementStateMessage -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                } catch {
                    Write-Verbose "`tUnable to get Enforcement State Message data"
                }

                $enforcementState = $enforcementStateMessage.EnforcementState
                if ($enforcementState) {
                    switch ($enforcementState) {
                        1000	{ $enforcementState = "Succeeded" }
                        1003	{ $enforcementState = "Received command to install" }
                        2000	{ $enforcementState = "Enforcement action is in progress" }
                        2007	{ $enforcementState = "App enforcement will be attempted once all dependent apps have been installed" }
                        2008	{ $enforcementState = "App has been installed but is not usable until device has rebooted" }
                        2009	{ $enforcementState = "App has been downloaded but no installation has been attempted" }
                        3000	{ $enforcementState = "Enforcement action aborted due to requirements not being met" }
                        4000	{ $enforcementState = "Enforcement action could not be completed due to unknown reason" }
                        5000	{ $enforcementState = "Enforcement action failed due to error.  Error code needs to be checked to determine detailed status" }
                        5003	{ $enforcementState = "Client was unable to download app content." }
                        5999	{ $enforcementState = "Enforcement action failed due to error, will retry immediately." }
                        6000	{ $enforcementState = "Enforcement action has not been attempted.  No reason given." }
                        6001	{ $enforcementState = "App install is blocked because one or more of the app's dependencies failed to install." }
                        6002	{ $enforcementState = "App install is blocked on the machine due to a pending hard reboot." }
                        6003	{ $enforcementState = "App install is blocked because one or more of the app's dependencies have requirements which are not met." }
                        6004	{ $enforcementState = "App is a dependency of another application and is configured to not automatically install." }
                        6005	{ $enforcementState = "App install is blocked because one or more of the app's dependencies are configured to not automatically install." }
                        default { Write-Error "Undefined enforcement status $enforcementState" }
                    }
                }

                $lastError = $complianceStateMessage.ErrorCode
                if (!$lastError) { $lastError = 0 } # because of HTML conditional formatting ($null means that cell will have red background)
                #endregion get Win32App data

                #TODO I don't differentiate between user and device scope, but it seems log contains just user data?
                $appLogData = $logData | ? Id -EQ $win32AppID
                $appLogReportingData = $logReportingData | ? Id -EQ $win32AppID

                #region output the results
                # prepare final object properties
                $property = [ordered]@{
                    "Name"               = ''
                    "Id"                 = $win32AppID
                    "Scope"              = _getTargetName $userAzureObjectID
                    "LastUpdatedTimeUtc" = $lastUpdatedTimeUtc
                    "ComplianceState"    = $complianceState
                    "EnforcementState"   = $enforcementState
                    "EnforcementError"   = Get-Win32AppErrMsg $enforcementStateMessage.ErrorCode
                    "LastError"          = $lastError
                    "ProductVersion"     = $complianceStateMessage.ProductVersion
                    "DesiredState"       = $desiredState
                    # "EnforcementErrorCode" = $enforcementStateMessage.ErrorCode
                    "DeploymentType"     = $deploymentType
                    "ScopeId"            = $userAzureObjectID
                }
                if ($getDataFromIntune) {
                    $property.Name = ($intuneApp | ? id -EQ $win32AppID).DisplayName
                } else {
                    $property.Name = if ($appLogData.Name) { $appLogData.Name } else { $appLogReportingData.Name }
                }

                # add additional properties when possible
                if ($appLogData) {
                    Write-Verbose "Enrich app object data with information found in Intune log files"

                    $appLogData = $appLogData | select * -ExcludeProperty Id, Name

                    $newProperty = Get-Member -InputObject $appLogData -MemberType NoteProperty
                    $newProperty | % {
                        $propertyName = $_.Name
                        $propertyValue = $appLogData.$propertyName

                        $property.$propertyName = $propertyValue
                    }
                } else {
                    Write-Verbose "For app $win32AppID there are no extra information in Intune log files"
                }

                New-Object -TypeName PSObject -Property $property
                #endregion output the results
            }
        }

        #region warn about deployed but skip-installation apps
        #TODO name is missing often
        # if ($logReportingData) {
        #     $notProcessedApp = $logReportingData | ? { $_.Id -notin $processedWin32AppId}
        #     if ($notProcessedApp) {
        #         Write-Warning "Following apps didn't start installation: $($notProcessedApp.Name -join ', ')`n`nReason can be recent forced redeploy of such app or that deployment requirements are not met. For more information run 'Get-IntuneLogWin32AppReportingResultData'"
        #     }
        # }
        #endregion warn about deployed but skip-installation apps
    }

    $param = @{
        scriptBlock  = $scriptBlock
        argumentList = ($VerbosePreference, $excludeSystemApp, $getDataFromIntune, $intuneApp, $intuneUser, $allFunctionDefs)
    }
    if ($computerName) {
        $param.session = $session
    }

    $win32App = Invoke-Command @param | select -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
    #endregion get data

    #region let user redeploy chosen app
    if ($win32App) {
        $win32App
    } else {
        Write-Warning "No deployed Win32App detected"
    }
    #endregion let user redeploy chosen app

    if ($computerName) {
        Remove-PSSession $session
    }
}