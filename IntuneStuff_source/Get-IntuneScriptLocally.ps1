﻿function Get-IntuneScriptLocally {
    <#
    .SYNOPSIS
    Function for showing (non-remediation) scripts deployed from Intune to local/remote computer.

    Script details are gathered from clients registry (HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies) and if 'includeScriptContent' parameter is used, script content is gathered during forced redeploy of the scripts.

    .DESCRIPTION
    Function for showing (non-remediation) scripts deployed from Intune to local/remote computer.

    Script details are gathered from clients registry (HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies) and if 'includeScriptContent' parameter is used, script content is gathered during forced redeploy of the scripts.

    .PARAMETER computerName
    Name of remote computer where you want to force the redeploy.

    .PARAMETER includeScriptContent
    Switch for including Intune scripts content.

    This will need administrator rights and lead to redeploy of all such scripts to the client!

    .PARAMETER force
    Switch for skipping script redeploy confirmation.

    .EXAMPLE
    Get-IntuneScriptLocally

    Get and show (non-remediation) script(s) deployed from Intune to this computer. Script content will NOT be included.

    .EXAMPLE
    Get-IntuneScriptLocally -includeScriptContent

    Get and show (non-remediation) script(s) deployed from Intune to this computer. Script content will be included.
    #>

    [CmdletBinding()]
    param (
        [string] $computerName,

        [switch] $includeScriptContent,

        [switch] $force,

        [switch] $getDataFromIntune
    )

    if (!$computerName) {
        # access to registry key "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension" now needs admin permission
        if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "Function '$($MyInvocation.MyCommand)' needs to be run with administrator permission"
        }
    }

    #region helper function
    function _getIntuneScript {
        param ([string] $scriptID)

        $intuneScript | ? id -EQ $scriptID
    }

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

    # create helper functions text definition for usage in remote sessions
    if ($computerName) {
        $allFunctionDefs = "function _getTargetName { ${function:_getTargetName} }; function _getIntuneScript { ${function:_getIntuneScript} }; function Get-IntuneScriptContentLocally { ${function:Get-IntuneScriptContentLocally} }"
    }
    #endregion helper function

    #region prepare
    if ($getDataFromIntune) {
        if (!(Get-Command Get-MgContext -ErrorAction silentlycontinue) -or !(Get-MgContext)) {
            throw "$($MyInvocation.MyCommand): Authentication needed. Please call Connect-MgGraph."
        }

        Write-Verbose "Getting Intune data"
        # filtering by ID is as slow as getting all data
        $intuneScript = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?select=id,displayname" | Get-MgGraphAllPages
        $intuneUser = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/beta/users?select=id,userPrincipalName' | Get-MgGraphAllPages
    }

    if ($computerName) {
        $session = New-PSSession -ComputerName $computerName -ErrorAction Stop
    }
    #endregion prepare

    #region get data
    $scriptBlock = {
        param ($verbosePref, $getDataFromIntune, $intuneScript, $intuneUser, $allFunctionDefs, $includeScriptContent, $force)

        # inherit verbose settings from host session
        $VerbosePreference = $verbosePref

        # caching of script ID > Name translations
        $scriptNameList = @{}

        # recreate functions from their text definitions
        . ([ScriptBlock]::Create($allFunctionDefs))

        if ($includeScriptContent) {
            if ($force) {
                $scriptContent = Get-IntuneScriptContentLocally -force
            } else {
                $scriptContent = Get-IntuneScriptContentLocally
            }
        }

        Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies" -ErrorAction SilentlyContinue | % {
            $userAzureObjectID = Split-Path $_.Name -Leaf

            Get-ChildItem $_.PSPath | % {
                $scriptRegPath = $_.PSPath
                $scriptID = Split-Path $_.Name -Leaf

                Write-Verbose "`tID $scriptID"

                $scriptRegData = Get-ItemProperty $scriptRegPath

                # get output of the invoked script
                if ($scriptRegData.ResultDetails) {
                    try {
                        $resultDetails = $scriptRegData.ResultDetails | ConvertFrom-Json -ErrorAction Stop | select -ExpandProperty ExecutionMsg
                    } catch {
                        Write-Verbose "`tUnable to get Script Output data"
                    }
                } else {
                    $resultDetails = $null
                }

                if ($getDataFromIntune) {
                    $property = [ordered]@{
                        "Scope"                   = _getTargetName $userAzureObjectID
                        "DisplayName"             = (_getIntuneScript $scriptID).DisplayName
                        "Id"                      = $scriptID
                        "Result"                  = $scriptRegData.Result
                        "ErrorCode"               = $scriptRegData.ErrorCode
                        "DownloadAndExecuteCount" = $scriptRegData.DownloadCount
                        "LastUpdatedTimeUtc"      = $scriptRegData.LastUpdatedTimeUtc
                        "RunAsAccount"            = $scriptRegData.RunAsAccount
                        "ResultDetails"           = $resultDetails
                    }
                } else {
                    # no 'DisplayName' property
                    $property = [ordered]@{
                        "Scope"                   = _getTargetName $userAzureObjectID
                        "Id"                      = $scriptID
                        "Result"                  = $scriptRegData.Result
                        "ErrorCode"               = $scriptRegData.ErrorCode
                        "DownloadAndExecuteCount" = $scriptRegData.DownloadCount
                        "LastUpdatedTimeUtc"      = $scriptRegData.LastUpdatedTimeUtc
                        "RunAsAccount"            = $scriptRegData.RunAsAccount
                        "ResultDetails"           = $resultDetails
                    }
                }

                if ($scriptContent) {
                    $property.Content = $scriptContent | ? Id -EQ $scriptID | select -ExpandProperty Content
                }

                New-Object -TypeName PSObject -Property $property
            }
        }
    }

    $param = @{
        scriptBlock  = $scriptBlock
        argumentList = ($VerbosePreference, $getDataFromIntune, $intuneScript, $intuneUser, $allFunctionDefs, $includeScriptContent, $force)
    }
    if ($computerName) {
        $param.session = $session
    }

    Invoke-Command @param | select -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
    #endregion get data

    if ($computerName) {
        Remove-PSSession $session
    }
}