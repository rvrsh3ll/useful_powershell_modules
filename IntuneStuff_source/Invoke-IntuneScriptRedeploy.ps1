﻿function Invoke-IntuneScriptRedeploy {
    <#
    .SYNOPSIS
    Function for forcing redeploy of selected Script(s) deployed from Intune.
    Scripts and Remediation scripts can be redeployed.

    .DESCRIPTION
    Function for forcing redeploy of selected Script(s) deployed from Intune.
    Scripts and Remediation scripts can be redeployed.

    OutGridView is used to output found Scripts.

    Redeploy means that corresponding registry keys will be deleted from registry and service IntuneManagementExtension will be restarted.

    .PARAMETER computerName
    Name of remote computer where you want to force the redeploy.

    .PARAMETER scriptType
    Mandatory parameter for selecting type of the script you want to show&redeploy.
    Possible values are script, remediationScript.

    .PARAMETER getDataFromIntune
    Switch for getting Scripts and User names from Intune, so locally used IDs can be translated to them.

    .PARAMETER all
    Switch to redeploy all scripts of selected type (script, remediationScript).

    .PARAMETER dontWait
    Don't wait on script execution completion.

    .PARAMETER noDetails
    Show just basic script data in the GUI.

    .EXAMPLE
    Invoke-IntuneScriptRedeploy -scriptType script

    Get and show common Script(s) deployed from Intune to this computer. Selected ones will be then redeployed.

    .EXAMPLE
    Invoke-IntuneScriptRedeploy -scriptType remediationScript

    Get and show Remediation Script(s) deployed from Intune to this computer. Selected ones will be then redeployed.

    .EXAMPLE
    Connect-MgGraph

    Invoke-IntuneScriptRedeploy -scriptType remediationScript -computerName PC-01 -getDataFromIntune

    Get and show Script(s) deployed from Intune to computer PC-01. IDs of scripts and targeted users will be translated to corresponding names. Selected ones will be then redeployed.
    #>

    [CmdletBinding()]
    [Alias("Invoke-IntuneScriptRedeployLocally")]
    param (
        [string] $computerName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('script', 'remediationScript')]
        [string] $scriptType,

        [Alias("online")]
        [switch] $getDataFromIntune,

        [switch] $all,

        [switch] $dontWait,

        [switch] $noDetails
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

    function _getRemediationScript {
        param ([string] $scriptID)
        $intuneRemediationScript | ? id -EQ $scriptID
    }
    function _getTargetName {
        param ([string] $id)

        Write-Verbose "Translating $id"

        if (!$id) {
            Write-Verbose "id was null"
            return
        } elseif ($id -eq 'device') {
            # xml nodes contains 'device' instead of 'Device'
            return 'Device'
        }

        $errPref = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        try {
            if ($id -eq '00000000-0000-0000-0000-000000000000' -or $id -eq 'S-0-0-00-0000000000-0000000000-000000000-000') {
                return 'Device'
            } elseif ($id -match "^S-1-5-21") {
                # it is local account
                return ((New-Object System.Security.Principal.SecurityIdentifier($id)).Translate([System.Security.Principal.NTAccount])).Value
            } else {
                # it is AzureAD account
                if ($getDataFromIntune) {
                    return ($intuneUser | ? id -EQ $id).userPrincipalName
                } else {
                    # unable to translate ID to name because there is no connection to the Intune Graph API
                    return $id
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
        $allFunctionDefs = "function _getTargetName { ${function:_getTargetName} }; function _getIntuneScript { ${function:_getIntuneScript} }; function _getRemediationScript { ${function:_getRemediationScript} }"
    }
    #endregion helper function

    #region prepare
    if ($getDataFromIntune) {
        if (!(Get-Command Get-MgContext -ErrorAction silentlycontinue) -or !(Get-MgContext)) {
            throw "$($MyInvocation.MyCommand): Authentication needed. Please call Connect-MgGraph."
        }

        Write-Verbose "Getting Intune data"
        # filtering by ID is as slow as getting all data
        if ($scriptType -eq "remediationScript") {
            $intuneRemediationScript = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?select=id,displayname" | Get-MgGraphAllPages
        }
        if ($scriptType -eq "script") {
            $intuneScript = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?select=id,displayname" | Get-MgGraphAllPages
        }
        $intuneUser = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/beta/users?select=id,userPrincipalName' | Get-MgGraphAllPages
    }

    if ($computerName) {
        $session = New-PSSession -ComputerName $computerName -ErrorAction Stop
    } else {
        if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "Run as administrator"
        }
    }
    #endregion prepare

    #region get data
    if ($scriptType -eq 'script') {
        #region script
        $scriptBlock = {
            param($verbosePref, $getDataFromIntune, $intuneScript, $intuneUser, $allFunctionDefs, $noDetails)

            # inherit verbose settings from host session
            $VerbosePreference = $verbosePref

            # recreate functions from their text definitions
            . ([ScriptBlock]::Create($allFunctionDefs))

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
                            "ScopeId"                 = $userAzureObjectID
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
                            "ScopeId"                 = $userAzureObjectID
                        }
                    }

                    if ($noDetails) {
                        'DownloadAndExecuteCount', 'ResultDetails' | % {
                            $property.Remove($_)
                        }
                    }

                    New-Object -TypeName PSObject -Property $property
                }
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = ($VerbosePreference, $getDataFromIntune, $intuneScript, $intuneUser, $allFunctionDefs, $noDetails)
        }
        if ($computerName) {
            $param.session = $session
        }

        $script = Invoke-Command @param | select -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
        #region script
    }

    #region remediation script
    if ($scriptType -eq 'remediationScript') {
        $scriptBlock = {
            param($verbosePref, $getDataFromIntune, $intuneRemediationScript, $intuneUser, $allFunctionDefs, $noDetails)

            # inherit verbose settings from host session
            $VerbosePreference = $verbosePref

            # recreate functions from their text definitions
            . ([ScriptBlock]::Create($allFunctionDefs))

            Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Reports" -ErrorAction SilentlyContinue | % {
                $userAzureObjectID = Split-Path $_.Name -Leaf
                $userRemScriptRoot = $_.PSPath

                # $lastFullReportTimeUTC = Get-ItemPropertyValue $userRemScriptRoot -Name LastFullReportTimeUTC
                $remScriptIDList = Get-ChildItem $userRemScriptRoot | select -ExpandProperty PSChildName | % { $_ -replace "_\d+$" } | select -Unique

                $remScriptIDList | % {
                    $remScriptID = $_

                    Write-Verbose "`tID $remScriptID"

                    $newestRemScriptRecord = Get-ChildItem $userRemScriptRoot | ? PSChildName -Match ([regex]::escape($remScriptID)) | Sort-Object -Descending -Property PSChildName | select -First 1

                    try {
                        $result = Get-ItemPropertyValue "$($newestRemScriptRecord.PSPath)\Result" -Name Result | ConvertFrom-Json
                    } catch {
                        Write-Verbose "`tUnable to get Remediation Script Result data"
                    }

                    $lastExecution = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Execution\$userAzureObjectID\$($newestRemScriptRecord.PSChildName)" -Name LastExecution

                    if ($getDataFromIntune) {
                        $property = [ordered]@{
                            "Scope"                             = _getTargetName $userAzureObjectID
                            "DisplayName"                       = (_getRemediationScript $remScriptID).DisplayName
                            "Id"                                = $remScriptID
                            "LastError"                         = $result.ErrorCode
                            "LastExecution"                     = $lastExecution
                            # LastFullReportTimeUTC               = $lastFullReportTimeUTC
                            "InternalVersion"                   = $result.InternalVersion
                            "PreRemediationDetectScriptOutput"  = $result.PreRemediationDetectScriptOutput
                            "PreRemediationDetectScriptError"   = $result.PreRemediationDetectScriptError
                            "RemediationScriptErrorDetails"     = $result.RemediationScriptErrorDetails
                            "PostRemediationDetectScriptOutput" = $result.PostRemediationDetectScriptOutput
                            "PostRemediationDetectScriptError"  = $result.PostRemediationDetectScriptError
                            "RemediationExitCode"               = $result.Info.RemediationExitCode
                            "FirstDetectExitCode"               = $result.Info.FirstDetectExitCode
                            "LastDetectExitCode"                = $result.Info.LastDetectExitCode
                            "ErrorDetails"                      = $result.Info.ErrorDetails
                            "ScopeId"                           = $userAzureObjectID
                        }
                    } else {
                        # no 'DisplayName' property
                        $property = [ordered]@{
                            "Scope"                             = _getTargetName $userAzureObjectID
                            "Id"                                = $remScriptID
                            "LastError"                         = $result.ErrorCode
                            "LastExecution"                     = $lastExecution
                            # LastFullReportTimeUTC               = $lastFullReportTimeUTC
                            "InternalVersion"                   = $result.InternalVersion
                            "PreRemediationDetectScriptOutput"  = $result.PreRemediationDetectScriptOutput
                            "PreRemediationDetectScriptError"   = $result.PreRemediationDetectScriptError
                            "RemediationScriptErrorDetails"     = $result.RemediationScriptErrorDetails
                            "PostRemediationDetectScriptOutput" = $result.PostRemediationDetectScriptOutput
                            "PostRemediationDetectScriptError"  = $result.PostRemediationDetectScriptError
                            "RemediationExitCode"               = $result.Info.RemediationExitCode
                            "FirstDetectExitCode"               = $result.Info.FirstDetectExitCode
                            "LastDetectExitCode"                = $result.Info.LastDetectExitCode
                            "ErrorDetails"                      = $result.Info.ErrorDetails
                            "ScopeId"                           = $userAzureObjectID
                        }
                    }

                    if ($noDetails) {
                        'InternalVersion', 'PreRemediationDetectScriptOutput', 'PreRemediationDetectScriptError', 'RemediationScriptErrorDetails', 'PostRemediationDetectScriptOutput', 'PostRemediationDetectScriptError', 'RemediationExitCode', 'FirstDetectExitCode', 'LastDetectExitCode', 'ErrorDetails' | % {
                            $property.Remove($_)
                        }
                    }

                    New-Object -TypeName PSObject -Property $property
                }
            }
        }

        $param = @{
            scriptBlock  = $scriptBlock
            argumentList = ($VerbosePreference, $getDataFromIntune, $intuneRemediationScript, $intuneUser, $allFunctionDefs, $noDetails)
        }
        if ($computerName) {
            $param.session = $session
        }

        $script = Invoke-Command @param | select -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
    }
    #endregion remediation script

    #endregion get data

    #region let user redeploy chosen app
    if ($script) {
        if ($all) {
            $scriptToRedeploy = $script
        } else {
            $scriptToRedeploy = $script | Out-GridView -PassThru -Title "Pick script(s) for redeploy"
        }

        if ($scriptToRedeploy) {
            $scriptBlock = {
                param ($verbosePref, $scriptToRedeploy, $scriptType, $dontWait)

                # inherit verbose settings from host session
                $VerbosePreference = $verbosePref

                if ($scriptType -eq 'script') {
                    $scriptKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Policies" -Recurse -Depth 2 | select PSChildName, PSPath, PSParentPath
                } elseif ($scriptType -eq 'remediationScript') {
                    # from Reports the key is deleted to be consistent (to have report without last execution can be weird)
                    $scriptKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Execution", "HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\SideCarPolicies\Scripts\Reports" -Recurse -Depth 2 | select PSChildName, PSPath, PSParentPath
                }

                $scriptToRedeploy | % {
                    $scriptId = $_.id
                    $scopeId = $_.scopeId
                    Write-Warning "Preparing redeploy for script $scriptId (scope $($_.scope)) by deleting it's registry key"

                    $win32AppKeyToDelete = $scriptKeys | ? { $_.PSChildName -Match "^$scriptId(_\d+)?" -and $_.PSParentPath -Match "\\$scopeId$" }

                    if ($win32AppKeyToDelete) {
                        $win32AppKeyToDelete | % {
                            Write-Verbose "Deleting $($_.PSPath)"
                            Remove-Item $_.PSPath -Force -Recurse
                        }
                    } else {
                        throw "BUG??? Script $scriptId with scope $scopeId wasn't found in the registry"
                    }
                }

                Write-Warning "Invoking redeploy (by restarting service IntuneManagementExtension). Redeploy can take several minutes!"
                Restart-Service IntuneManagementExtension -Force

                if (!$dontWait) {
                    if ($scriptType -eq 'script') {
                        Write-Warning "Waiting for start of the Intune script(s) redeploy (this can take minute or two)"
                        $null = Invoke-FileContentWatcher -path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log" -searchString "Prepare to run Powershell Script" -stopOnFirstMatch
                        Write-Warning "Waiting for the completion of the Intune script(s) redeploy (this can take several minutes!)"
                        $null = Invoke-FileContentWatcher -path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log" -searchString "Agent executor completed." -stopOnFirstMatch
                    } elseif ($scriptType -eq 'remediationScript') {
                        Write-Warning "Waiting for start of the Intune remediation script(s) redeploy (this can take minute or two)"
                        # [HS] Calcuated earliest time is 04.10.2022 15:26:25
                        $calculatedStart = Invoke-FileContentWatcher -path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -searchString "earliest time is" -stopOnFirstMatch
                        $calculatedStart = ([regex]"\d+\.\d+\.\d+ \d+:\d+:\d+").Match($calculatedStart).value
                        Write-Warning "Calculated start of the Intune remediation script(s) redeploy is set to $calculatedStart"
                        Write-Warning "Waiting for the completion of the Intune remediation script(s) redeploy"
                        $null = Invoke-FileContentWatcher -path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log" -searchString "Powershell exit code is" -stopOnFirstMatch # beware that this detects FIRST script finish..if user redeploy multiple scripts this will be confusing
                    }
                }
            }

            $param = @{
                scriptBlock  = $scriptBlock
                argumentList = ($VerbosePreference, $scriptToRedeploy, $scriptType, $dontWait)
            }
            if ($computerName) {
                $param.session = $session
            }

            Invoke-Command @param
        }
    } else {
        Write-Warning "No deployed script detected. Try to restart service 'IntuneManagementExtension'?"
    }
    #endregion let user redeploy chosen app

    if ($computerName) {
        Remove-PSSession $session
    }
}