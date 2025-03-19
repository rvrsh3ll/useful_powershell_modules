function Expand-MgAdditionalProperties {
    <#
    .SYNOPSIS
    Function for expanding 'AdditionalProperties' hash property to the main object aka flattens object.

    .DESCRIPTION
    Function for expanding 'AdditionalProperties' hash property to the main object aka flattens object.
    By default it is returned by commands like Get-MgDirectoryObjectById, Get-MgGroupMember etc.

    .PARAMETER inputObject
    Object returned by Mg* command that contains 'AdditionalProperties' property.

    .EXAMPLE
    Get-MgGroupMember -GroupId 90daa3a7-7fed-4fa7-a979-db74bcd7cbd0  | Expand-MgAdditionalProperties

    .EXAMPLE
    Get-MgDirectoryObjectById -ids 34568a12-8862-45cf-afef-9582cd9871c6 | Expand-MgAdditionalProperties
    #>

    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline)]
        [object] $inputObject
    )

    process {
        if ($inputObject.AdditionalProperties -and $inputObject.AdditionalProperties.gettype().name -eq 'Dictionary`2') {
            $inputObject.AdditionalProperties.GetEnumerator() | % {
                $item = $_
                Write-Verbose "Adding property '$($item.key)' to the pipeline object"
                $inputObject | Add-Member -MemberType NoteProperty -Name $item.key -Value $item.value

                if ($item.key -eq "@odata.type") {
                    Write-Verbose "Adding extra property 'ObjectType' to the pipeline object"
                    $inputObject | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value ($item.value -replace [regex]::Escape("#microsoft.graph."))
                }
            }

            $inputObject | Select-Object -Property * -ExcludeProperty AdditionalProperties
        } else {
            Write-Verbose "There is no 'AdditionalProperties' property"
            $inputObject
        }
    }
}

function Get-CodeGraphModuleDependency {
    <#
    .SYNOPSIS
    Function for getting Graph SDK modules required to run given code.

    .DESCRIPTION
    Function for getting Graph SDK modules required to run given code.
    It extracts all Graph commands using 'Get-CodeDependency' function (DependencySearch module).
    Modules that hosts found commands are retrieved using official 'Find-MgGraphCommand' command then.

    .PARAMETER scriptPath
    Path to ps1 script that should be analyzed.

    .PARAMETER availableModules
    To speed up repeated function invocations, save all available modules into variable and use it as value for this parameter.

    By default this function caches all locally available modules before each run which can take several seconds.

    .PARAMETER allOccurrences
    Switch to return all found Mg* commands and not just the first one for each PowerShell SDK module.

    .PARAMETER goDeep
    Switch to check for direct dependencies not just in the given code, but even indirect ones in its dependencies (recursively) == gets the whole dependency tree.

    By default ONLY the code in the 'scriptPath' is analyzed, but not the called commands/modules definitions!

    .EXAMPLE
    # cache available modules to speed up repeated 'Get-CodeGraphModuleDependency' function invocations
    $availableModules = @(Get-Module -ListAvailable)

    Get-CodeGraphModuleDependency -scriptPath C:\scripts\someGraphRelatedCode.ps1 -availableModules $availableModules

    Returns Graph SDK modules required by selected code.
    In case there are some indirect dependencies (like there is a function that has some Graph module dependency in its code), they won't be returned!

    .EXAMPLE
    Get-CodeGraphModuleDependency -scriptPath C:\scripts\someGraphRelatedCode.ps1 -goDeep

    Returns ALL Graph SDK modules required to run selected code (direct and indirect).

    .NOTES
    Requires module 'Microsoft.Graph.Authentication' because of 'Find-MgGraphCommand' command.
    #>

    [CmdletBinding()]
    [Alias("Get-GraphAPICodeModuleDependency")]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                if ((Test-Path -Path $_ -PathType leaf) -and $_ -match "\.ps1$") {
                    $true
                } else {
                    throw "$_ is not a ps1 file or it doesn't exist"
                }
            })]
        [string] $scriptPath,

        [System.Collections.ArrayList] $availableModules = @(),

        [switch] $allOccurrences,

        [switch] $goDeep
    )

    if (!(Get-Command "Find-MgGraphCommand" -ErrorAction SilentlyContinue)) {
        throw "'Find-MgGraphCommand' command is missing. Install 'Microsoft.Graph.Authentication' module and run again"
    }

    if (!(Get-Command "Get-CodeDependency" -ErrorAction SilentlyContinue)) {
        throw "'Get-CodeDependency' command is missing. Install 'DependencyStuff' module and run again"
    }

    $param = @{
        scriptPath                   = $scriptPath
        processJustMSGraphSDK        = $true
        dontSearchCommandInPSGallery = $true
    }
    if ($availableModules) {
        $param.availableModules = $availableModules
    }
    if ($goDeep) {
        $param.goDeep = $true
    }
    if ($allOccurrences) {
        $param.allOccurrences = $true
    }
    if ($PSBoundParameters.Verbose) {
        $param.Verbose = $true
    }

    Get-CodeDependency @param | ? { $_.Type -eq "Module" -and $_.Name -like "Microsoft.Graph.*" } | select * -ExcludeProperty Type
}

function Get-CodeGraphPermissionRequirement {
    <#
    .SYNOPSIS
    Function for getting Graph API permissions (scopes) that are needed to run selected code.

    Official Graph SDK commands AND direct Graph API calls are both processed :)

    .DESCRIPTION
    Function for getting Graph API permissions (scopes) that are needed to run selected code.

    All official Graph SDK commands (*-Mg*) AND commands making direct Graph API calls (Invoke-MsGraphRequest, Invoke-RestMethod, Invoke-WebRequest and their aliases) are extracted using 'Get-CodeDependency' function (DependencySearch module).
    Permissions required to use these commands are retrieved using official 'Find-MgGraphCommand' command then.

    By default not all found permissions are returned, but just filtered subset, to make the output more readable and support principle of least privilege. Check parameter 'dontFilterPermissions' help for more details.

    .PARAMETER scriptPath
    Path to ps1 script that should be analyzed.

    .PARAMETER permType
    What type of permissions you want to retrieve.

    Possible values: Application, DelegatedWork, DelegatedPersonal.

    By default 'Application'.

    .PARAMETER availableModules
    To speed up repeated function invocations, save all available modules into variable and use it as value for this parameter.

    By default this function caches all locally available modules before each run which can take several seconds.

    .PARAMETER goDeep
    Switch to check for dependencies not just in the given code, but even in its dependencies (recursively). A.k.a. get the whole dependency tree.

    .PARAMETER dontFilterPermissions
    Switch to output all found permissions a.k.a. not to make any filtering.

    Otherwise just privileges marked as IsLeastPrivilege (if found) are returned or the ones guessed as the least ones (filtered by following internal logic).
    - if it is READ command (GET)
        - READWRITE permissions that have corresponding READ permission are ignored
        - directory.* permissions are ignored if any other permission is in place
    - if it is MODIFYING command (POST, PUT, PATCH, DELETE)
        - READ permissions that have corresponding READWRITE permission are ignored
        - directory.* permissions are ignored if any other permission is in place

    Beware that to read some sensitive data (like encrypted OMA Settings), you really need ReadWrite permission (because of security reasons)! In such cases, you need to select the 'dontFilterPermissions' parameter.

    .EXAMPLE
    Get-CodeGraphPermissionRequirement -scriptPath C:\scripts\someGraphRelatedCode.ps1 | Out-GridView

    Returns Graph permissions of 'Application' type required by selected script.
    In case there are some indirect dependencies (like there is used some external function that has some inner Graph calls in its code), they won't be analyzed/returned!
    Result will be showed in Out-GridView graphical window.

    .EXAMPLE
    # cache available modules to speed up repeated 'Get-CodeGraphPermissionRequirement' function invocations
    $availableModules = @(Get-Module -ListAvailable)

    Get-CodeGraphPermissionRequirement -scriptPath C:\scripts\someGraphRelatedCode.ps1 -goDeep -availableModules $availableModules -dontFilterPermissions | Out-GridView

    Returns ALL 'Application' type Graph permissions required to run selected code (direct and indirect).

    .NOTES
    Requires module 'Microsoft.Graph.Authentication' (at least version 2.18.0), because of 'Find-MgGraphCommand' command.

    Be noted that it is impossible to tell whether found permissions for some command are all required, or just some subset of them (for least-privileged access). Consult the Microsoft Graph Permissions Reference documentation to identify the least-privileged permission for your use case :(

    Direct API calls made via parameter splatting aren't detected. Its in my TODO list.
    #>

    [CmdletBinding()]
    [Alias("Get-CodeGraphPermission", "Get-CodeGraphScope", "Get-GraphAPICodePermission", "Get-GraphAPICodeScope")]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                if ((Test-Path -Path $_ -PathType leaf) -and $_ -match "\.ps1$") {
                    $true
                } else {
                    throw "$_ is not a ps1 file or it doesn't exist"
                }
            })]
        [string] $scriptPath,

        [ValidateSet('Application', 'DelegatedWork', 'DelegatedPersonal')]
        [string] $permType = 'Application',

        [System.Collections.ArrayList] $availableModules = @(),

        [switch] $goDeep,

        [switch] $dontFilterPermissions
    )

    $commandData = Get-Command "Find-MgGraphCommand" -ErrorAction SilentlyContinue
    if (!$commandData) {
        throw "'Find-MgGraphCommand' command is missing. Install 'Microsoft.Graph.Authentication' module and run again"
    } elseif ($commandData.Version -lt "2.18.0") {
        # older versions returns different data
        throw "At least version '2.18.0' of the 'Microsoft.Graph.Authentication' module is required for 'Find-MgGraphCommand' command to work properly."
    }

    if (!(Get-Command "Get-CodeDependency" -ErrorAction SilentlyContinue)) {
        throw "'Get-CodeDependency' command is missing. Install 'DependencyStuff' module and run again"
    }

    # commands that can be used to directly call Graph API
    $webCommandList = "Invoke-MgGraphRequest", "Invoke-MsGraphRequest", "Invoke-RestMethod", "irm", "Invoke-WebRequest", "curl", "iwr", "wget"

    $param = @{
        scriptPath                   = $scriptPath
        processJustMSGraphSDK        = $true
        allOccurrences               = $true
        dontSearchCommandInPSGallery = $true
        processEveryTime             = $webCommandList
    }
    if ($availableModules) {
        $param.availableModules = $availableModules
    }
    if ($goDeep) {
        $param.goDeep = $true
    }

    # get all commands which belongs to Graph SDK modules or are web invocations
    $usedGraphCommand = Get-CodeDependency @param | ? { ($_.Type -eq "Module" -and $_.Name -like "Microsoft.Graph.*" -and $_.RequiredBy -ne '<requires statement>' -and $_.RequiredBy -notmatch "^Import-Module|^ipmo") -or $_.DependencyPath[-1] -in $webCommandList }

    $processedGraphCommand = @()

    if ($usedGraphCommand) {
        foreach ($mgCommandData in $usedGraphCommand) {
            $mgCommand = @($mgCommandData.DependencyPath)[-1]
            $dependencyPath = $mgCommandData.DependencyPath
            $invocationText = $mgCommandData.RequiredBy
            $method = $null
            $apiVersion = $null

            Write-Verbose "Processing: $invocationText"

            if ($mgCommand -in "Connect-MgGraph", "Get-MgContext") {
                # no permission needed
                continue
            }

            if ($mgCommand -in $processedGraphCommand) {
                continue
            }

            #region get required Graph permission
            if ($mgCommand -in $webCommandList) {
                # processing a "web" command (direct API call)

                #region get called URI
                if ($mgCommand -in "Invoke-MgGraphRequest", "Invoke-MsGraphRequest") {
                    # these commands should have call Graph API, hence more relaxed search for Graph URI
                    $uri = $invocationText -split " " | ? { $_ -like "*graph.microsoft.com/*" -or $_ -like "*v1.0/*" -or $_ -like "*beta/*" -or $_ -like "*/*" }
                } elseif ($mgCommand -in "Invoke-RestMethod", "irm", "Invoke-WebRequest", "curl", "iwr", "wget") {
                    # these commands can, but don't have to call Graph API, hence more restrictive search for Graph URI
                    $uri = $invocationText -split " " | ? { $_ -like "*graph.microsoft.com/*" -or $_ -like "*v1.0/*" -or $_ -like "*beta/*" }
                } else {
                    throw "$mgCommand is in `$webCommandList, but missing elseif statement in the function code. Fix it"
                }

                if (!$uri) {
                    if ($invocationText -like "Invoke-MgGraphRequest *" -or $invocationText -like "Invoke-MsGraphRequest *") {
                        # Invoke-MgGraphRequest and Invoke-MsGraphRequest commands for sure uses Graph Api, hence output empty object to highlight I was unable to extract it
                        Write-Warning "Unable to extract URI from '$invocationText'. Skipping."
                        '' | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $null } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { $null } }, @{n = 'Method'; e = { $null } }, @{n = 'IsAdmin'; e = { $null } }, @{n = 'ErrorMsg'; e = { "Unable to extract URI" } }
                    } else {
                        Write-Verbose "Unable to extract URI from '$invocationText' or it is not a Graph URI. Skipping."
                    }

                    continue
                }
                #endregion get called URI

                #region convert called URI to searchable form
                # get rid of quotes
                $uri = $uri -replace "`"|'"
                # get rid of filter section
                $uri = ($uri -split "\?")[0]
                # replace variables for {id} placeholder (it is just guessing that user put variable int he url instead of ID)
                $uri = $uri -replace "\$[^/]+", "{id}"
                #endregion convert called URI to searchable form

                # find requested method
                $method = $invocationText -split " " | ? { $_ -in "GET", "POST", "PUT", "PATCH", "DELETE" }
                if (!$method) {
                    # select the default method
                    $method = "GET"
                }

                # find requested api version
                if ($uri -like "*beta*") {
                    $apiVersion = "beta"
                } else {
                    $apiVersion = "v1.0"
                }

                # find graph command/permission(s) for called URI, Method and Api version
                try {
                    Write-Verbose "Get permissions for URI: '$uri', Method: $method, ApiVersion: $apiVersion"
                    $mgCommandPerm = Find-MgGraphCommand -Uri $uri -Method $method -ApiVersion $apiVersion -ErrorAction Stop | ? Permissions | select -First 1 -ExpandProperty Permissions

                    if (!$mgCommandPerm) {
                        # try again with not as specific uri (higher chance it will find some permission)
                        $uriSplitted = $uri.split("/")
                        $uri = $uriSplitted[0..($uriSplitted.count - 2)] -join "/"
                        $mgCommandPerm = Find-MgGraphCommand -Uri $uri -Method $method -ApiVersion $apiVersion -ErrorAction Stop | ? Permissions | select -First 1 -ExpandProperty Permissions
                    }
                } catch {
                    Write-Warning "'Find-MgGraphCommand' was unable to find permissions for URI: '$uri', Method: $method, ApiVersion: $apiVersion"
                    '' | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $null } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { $apiVersion } }, @{n = 'Method'; e = { $method } }, @{n = 'IsAdmin'; e = { $null } }, @{n = 'ErrorMsg'; e = { "'Find-MgGraphCommand' was unable to find permissions for given URI, Method and ApiVersion" } }
                    continue
                }
            } else {
                # processing a built-in graph sdk command
                $processedGraphCommand += $mgCommand

                # find graph permission(s) for called Graph SDK command
                try {
                    $mgCommandPerm = Find-MgGraphCommand -Command $mgCommand -ErrorAction Stop | ? Permissions | select -First 1 -ExpandProperty Permissions
                } catch {
                    Write-Warning "'Find-MgGraphCommand' was unable to find command '$mgCommand'?!"
                    continue
                }
            }
            #endregion get required Graph permission

            if ($mgCommandPerm) {
                # some Graph permissions are required

                $mgCommandPerm = $mgCommandPerm | ? PermissionType -EQ $permType

                #region helper functions
                function _apiVersion {
                    if ($apiVersion) {
                        # URI invocation
                        return $apiVersion
                    } else {
                        # Graph command invocation
                        return (Find-MgGraphCommand -Command $mgCommand).APIVersion | select -Unique
                    }
                }

                function _method {
                    if ($method) {
                        # URI invocation
                        return $method
                    } else {
                        # Graph command invocation
                        return (Find-MgGraphCommand -Command $mgCommand).Method | select -Unique
                    }
                }
                #endregion helper functions

                if ($mgCommandPerm) {
                    if ($dontFilterPermissions) {
                        Write-Verbose "Returning all found permissions of the '$permType' type: $($mgCommandPerm.Name)"

                        $mgCommandPerm | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $_.PermissionType } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { _apiVersion } }, @{n = 'Method'; e = { _method $mgCommand } }, IsAdmin, @{n = 'ErrorMsg'; e = { $null } }
                    } else {
                        $leastPrivilege = $mgCommandPerm | ? IsLeastPrivilege

                        if ($leastPrivilege) {
                            # there is some permission marked as least privileged, output just that

                            Write-Verbose "Returning just 'IsLeastPrivilege' marked permissions of the '$permType' type: $($leastPrivilege.Name)"

                            $leastPrivilege | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $_.PermissionType } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { _apiVersion } }, @{n = 'Method'; e = { _method $mgCommand } }, IsAdmin, @{n = 'ErrorMsg'; e = { $null } }
                        } else {
                            # there isn't any permission marked as least privileged, do some filtering magic

                            Write-Verbose "Returning just least-privilege-best-guess subset of permissions of the '$permType' type: $($mgCommandPerm.Name)"

                            if ((_method $mgCommand) -eq "GET") {
                                # the command just READs data

                                $mgCommandPerm = $mgCommandPerm | ? {
                                    $permission = $_.Name
                                    $isWritePermission = $permission -like "*.ReadWrite.*"

                                    if ($permission -like "Directory.*") {
                                        $someOtherPermission = $mgCommandPerm | ? { $_.Name -notlike "Directory.*" -and $_.Name -like "*.Read.*" }

                                        if ($someOtherPermission) {
                                            Write-Verbose "Skipping DIRECTORY permission $permission. There is some other least-priv permission in place ($($someOtherPermission.name))"
                                            return $false
                                        }
                                    } elseif ($isWritePermission) {
                                        $correspondingReadPermission = $mgCommandPerm | ? Name -EQ ($permission -replace "\.ReadWrite\.", ".Read.")

                                        if ($correspondingReadPermission) {
                                            # don't output, there is same but just READ permission in place
                                            Write-Verbose "Skipping READWRITE permission $permission. There is some other READ permission in place ($($correspondingReadPermission.name))"
                                            return $false
                                        }
                                    }

                                    return $true
                                }

                                $mgCommandPerm | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $_.PermissionType } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { _apiVersion } }, @{n = 'Method'; e = { _method $mgCommand } }, IsAdmin, @{n = 'ErrorMsg'; e = { $null } }
                            } else {
                                # the command MODIFIES data

                                $mgCommandPerm = $mgCommandPerm | ? {
                                    $permission = $_.Name
                                    $isReadPermission = $permission -like "*.Read.*"

                                    if ($permission -like "Directory.*") {
                                        $someOtherPermission = $mgCommandPerm | ? { $_.Name -notlike "Directory.*" -and $_.Name -like "*.ReadWrite.*" }

                                        if ($someOtherPermission) {
                                            Write-Verbose "Skipping DIRECTORY permission $permission. There is some other least-priv permission in place ($($someOtherPermission.name))"
                                            return $false
                                        }
                                    } elseif ($isReadPermission) {
                                        $correspondingWritePermission = $mgCommandPerm | ? Name -EQ ($permission -replace "\.Read\.", ".ReadWrite.")

                                        if ($correspondingWritePermission) {
                                            # don't output, there is same but READWRITE permission in place
                                            Write-Verbose "Skipping READ permission $permission. There is some other READWRITE permission in place ($($correspondingWritePermission.name))"
                                            return $false
                                        }
                                    }

                                    return $true
                                }

                                $mgCommandPerm | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $_.PermissionType } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { _apiVersion } }, @{n = 'Method'; e = { _method $mgCommand } }, IsAdmin, @{n = 'ErrorMsg'; e = { $null } }
                            }
                        }
                    }
                } else {
                    Write-Warning "$mgCommand requires some permissions, but not of '$permType' type"
                }
            } else {
                # no Graph permissions are required?!
                if ($mgCommand -in $webCommandList) {
                    $cmd = $invocationText
                } else {
                    $cmd = $mgCommand
                }
                Write-Verbose "'$cmd' doesn't need any permissions?!"
                '' | select @{n = 'Command'; e = { $mgCommand } }, Name, Description, FullDescription, @{n = 'Type'; e = { $null } }, @{n = 'InvokedAs'; e = { $invocationText } }, @{n = 'DependencyPath'; e = { $dependencyPath } }, @{n = 'ApiVersion'; e = { _apiVersion $mgCommand } }, @{n = 'Method'; e = { _method $mgCommand } }, IsAdmin, @{n = 'ErrorMsg'; e = { $null } }
            }
        }
    } else {
        if ($goDeep) {
            Write-Warning "No Graph commands nor direct Graph API calls were found in '$scriptPath' or it's dependency tree"
        } else {
            Write-Warning "No Graph commands nor direct Graph API calls were found in '$scriptPath'"
        }
    }
}

function Get-MgGraphAllPages {
    <#
    .SYNOPSIS
    Function make sure that all api call pages are returned a.k.a. all results.

    .DESCRIPTION
    Function make sure that all api call pages are returned a.k.a. all results.

    .PARAMETER NextLink
    For internal use.

    .PARAMETER SearchResult
    For internal use.

    .PARAMETER AsHashTable
    Switch to return results as hashtable.
    By default returns pscustomobject.

    .EXAMPLE
    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps" | Get-MgGraphAllPages

    .NOTES
    Based on https://dev.to/celadin/get-mggraphallpages-the-mggraph-missing-command-45b5.
    #>

    [CmdletBinding(
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'SearchResult'
    )]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'NextLink', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('@odata.nextLink')]
        [string] $NextLink
        ,
        [Parameter(ParameterSetName = 'SearchResult', ValueFromPipeline = $true)]
        [PSObject] $SearchResult
        ,
        [switch] $AsHashTable
    )

    begin {}

    process {
        if (!$SearchResult) { return }

        if ($PSCmdlet.ParameterSetName -eq 'SearchResult') {
            # Set the current page to the search result provided
            $page = $SearchResult

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # We know this is a wrapper object if it has an "@odata.context" property
            #if (Get-Member -InputObject $page -Name '@odata.context' -Membertype Properties) {
            # MgGraph update - MgGraph returns hashtables, and almost always includes .context
            # instead, let's check for nextlinks specifically as a hashtable key
            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "First page value count: $($Page.'@odata.count')"
            }

            if ($page.ContainsKey('@odata.nextLink') -or $page.ContainsKey('value')) {
                $values = $page.value
            } else {
                # this will probably never fire anymore, but maybe.
                $values = $page
            }

            # Output the values
            if ($values) {
                if ($AsHashTable) {
                    # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
                    $values | Write-Output
                } else {
                    $values | ForEach-Object { [pscustomobject]$_ }
                }
            }
        }

        while (-Not ([string]::IsNullOrWhiteSpace($currentNextLink))) {
            # Make the call to get the next page
            try {
                $page = Invoke-MgGraphRequest -Uri $currentNextLink -Method GET
            } catch {
                throw $_
            }

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # Output the items in the page
            $values = $page.value

            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "Current page value count: $($Page.'@odata.count')"
            }

            if ($AsHashTable) {
                # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
                $values | Write-Output
            } else {
                $values | ForEach-Object { [pscustomobject]$_ }
            }
        }
    }

    end {}
}

function Invoke-GraphAPIRequest {
    <#
    .SYNOPSIS
    Function for creating request against Microsoft Graph API.

    .DESCRIPTION
    Function for creating request against Microsoft Graph API.

    It supports paging and throttling.

    .PARAMETER uri
    Request URI.

    https://graph.microsoft.com/v1.0/me/
    https://graph.microsoft.com/v1.0/devices
    https://graph.microsoft.com/v1.0/users
    https://graph.microsoft.com/v1.0/groups
    https://graph.microsoft.com/beta/servicePrincipals?&$expand=appRoleAssignedTo
    https://graph.microsoft.com/beta/servicePrincipals?$select=id,appId,servicePrincipalType,displayName
    https://graph.microsoft.com/beta/servicePrincipals?$filter=(servicePrincipalType%20eq%20%27ManagedIdentity%27)
    https://graph.microsoft.com/beta/servicePrincipals?$filter=contains(serialNumber,'$encoded')
    https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicySettingStateSummaries/1234/deviceComplianceSettingStates?`$filter=NOT(state eq 'compliant')
    https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$select=id&`$filter=complianceState eq 'compliant'
    https://graph.microsoft.com/beta/users?`$select=id,userPrincipalName,displayName,mail,otherMails,proxyAddresses&`$filter=proxyAddresses/any(c:c eq 'smtp:$technicalNotificationMail') or otherMails/any(c:c eq 'smtp:$technicalNotificationMail')

    .PARAMETER credential
    Credentials used for creating authentication header for request.

    .PARAMETER header
    Authentication header for request.

    .PARAMETER method
    Default is GET.

    .PARAMETER waitTime
    Number of seconds before new try in case of 'Too Many Requests' error.

    Default is 5 seconds.

    .EXAMPLE
    $header = New-GraphAPIAuthHeader -credential $intuneCredential
    $aadDevice = Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/devices" -header $header | Get-MSGraphAllPages

    .EXAMPLE
    $aadDevice = Invoke-GraphAPIRequest -Uri "https://graph.microsoft.com/v1.0/devices" -credential $intuneCredential | Get-MSGraphAllPages

    .NOTES
    https://configmgrblog.com/2017/12/05/so-what-can-we-do-with-microsoft-intune-via-microsoft-graph-api/
    #>

    [CmdletBinding()]
    [Alias("Invoke-MgRequest")]
    param (
        [Parameter(Mandatory = $true)]
        [string] $uri,

        [Parameter(Mandatory = $true, ParameterSetName = "credential")]
        [System.Management.Automation.PSCredential] $credential,

        [Parameter(Mandatory = $true, ParameterSetName = "header")]
        $header,

        [ValidateSet('GET', 'POST', 'DELETE', 'UPDATE')]
        [string] $method = "GET",

        [ValidateRange(1, 999)]
        [int] $waitTime = 5
    )

    Write-Verbose "uri $uri"

    if ($credential) {
        $header = New-GraphAPIAuthHeader -credential $credential
    }

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $header -Method $method -ErrorAction Stop
    } catch {
        switch ($_) {
            { $_ -like "*(429) Too Many Requests*" } {
                Write-Warning "(429) Too Many Requests. Waiting $waitTime seconds to avoid further throttling and try again"
                Start-Sleep $waitTime
                Invoke-GraphAPIRequest -uri $uri -header $header -method $method
            }
            { $_ -like "*(400) Bad Request*" } { throw "(400) Bad Request. There has to be some syntax/logic mistake in this request ($uri)" }
            { $_ -like "*(401) Unauthorized*" } { throw "(401) Unauthorized Request (new auth header has to be created?)" }
            { $_ -like "*Forbidden*" } { throw "Forbidden access. Use account with correct API permissions for this request ($uri)" }
            default { throw $_ }
        }
    }

    # sometimes the results is in Value property, sometimes it is the returned object itself
    if ($response -and ($response | Get-Member -MemberType NoteProperty -Name Value)) {
        $response.Value
    } else {
        $response
    }

    # understand if top parameter is used in the URI
    try {
        $prevErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        $topValue = ([regex]"top=(\d+)").Matches($uri).captures.groups[1].value
    } catch {
        Write-Verbose "uri ($uri) doesn't contain TOP"
    } finally {
        $ErrorActionPreference = $prevErrorActionPreference
    }

    if (!$topValue -or ($topValue -and $topValue -gt 100)) {
        # there can be more results to return, check that
        # need to loop the requests because only 100 results are returned each time
        $nextLink = $response.'@odata.nextLink'
        while ($nextLink) {
            Write-Verbose "Next uri $nextLink"
            try {
                $response = Invoke-RestMethod -Uri $NextLink -Headers $header -Method $method -ErrorAction Stop
            } catch {
                switch ($_) {
                    { $_ -like "*(429) Too Many Requests*" } {
                        Write-Warning "(429) Too Many Requests. Waiting $waitTime seconds to avoid further throttling and try again"
                        Start-Sleep $waitTime
                        Invoke-GraphAPIRequest -uri $NextLink -header $header -method $method
                    }
                    { $_ -like "*(400) Bad Request*" } { throw "(400) Bad Request. There has to be some syntax/logic mistake in this request ($uri)" }
                    { $_ -like "*(401) Unauthorized*" } { throw "(401) Unauthorized Request (new auth header has to be created?)" }
                    { $_ -like "*Forbidden*" } { throw "Forbidden access. Use account with correct API permissions for this request ($uri)" }
                    default { throw $_ }
                }
            }

            # sometimes the results is in Value property, sometimes it is the returned object itself
            if ($response -and ($response | Get-Member -MemberType NoteProperty -Name Value)) {
                $response.Value
            } else {
                $response
            }

            $nextLink = $response.'@odata.nextLink'
        }
    } else {
        # to avoid 'Too Many Requests' error when working with Graph API (/auditLogs/signIns) and using top parameter
        Write-Verbose "There is no need to check if more results can be returned. I.e. if parameter 'top' is used in the URI it is lower than 100 (so all results will be returned in the first request anyway)"
    }
}

function New-GraphAPIAuthHeader {
    <#
    .SYNOPSIS
    Function for generating header that can be used for authentication of Graph API requests (via Invoke-RestMethod).

    .DESCRIPTION
    Function for generating header that can be used for authentication of Graph API requests (via Invoke-RestMethod).

    Authentication can be done in several ways:
     - (default behavior) reuse existing AzureAD session created using Connect-AzAccount
        - advantages:
            - unattended
        - disadvantages:
            - token cannot be used for some high privilege API calls (you'll get forbidden error), check 'useMSAL' parameter help for more information
     - connect as a current user using MSAL authentication library
        - advantages:
            - token contains all user assigned delegated scopes
            - supports specifying permission scopes
        - disadvantages:
            - (can be) interactive
     - connect using application credentials
        - advantages:
            - unattended
            - token contains all granted application permissions
        - disadvantages:
            - you have to create such application and grant it required application permissions

    .PARAMETER credential
    Application credentials (AppID + AppSecret) that should be used (instead of the current user) to obtain auth. header.

    .PARAMETER tenantDomainName
    Name of your Azure tenant.
    Mandatory for application and MSAL authentication.

    For example: "contoso.onmicrosoft.com"

    .PARAMETER useMSAL
    Switch for using MSAL authentication library for auth. token creation.
    When 'credential' parameter is NOT used, existing AzureAD session will be used (created via Connect-AzAccount aka 'Azure PowerShell' app is used) to obtain the token.
    But such token will contains only 'Directory.AccessAsUser.All' delegated permission therefore it cannot be used for access API which requires high privileged permission.
    Such privileged calls will end with 'forbidden' error, so for such cases use MSAL authentication library instead. It uses 'Microsoft Graph PowerShell' app instead and returns all user assigned permission by default.

    For more information check https://github.com/Azure/azure-powershell/issues/14085#issuecomment-1163204817

    .PARAMETER tokenLifeTime
    Token lifetime in minutes.
    Will be saved into the header 'ExpiresOn' key and can be used for expiration detection (need to create new token).
    By default it is random number between 60 and 90 minutes (https://learn.microsoft.com/en-us/azure/active-directory/develop/access-tokens#access-token-lifetime) but can be changed in tenant policy.

    Default is 60.

    .PARAMETER scope
    Graph API permission scopes that should be requested when 'useMSAL' parameter is used.

    For example: 'https://graph.microsoft.com/User.Read', 'https://graph.microsoft.com/Files.ReadWrite'

    .EXAMPLE
    $cred = Get-Credential -Message "Enter application credentials (AppID + AppSecret) that should be used to obtain auth. header."
    $header = New-GraphAPIAuthHeader -credential $cred -tenantDomainName "contoso.onmicrosoft.com"

    $URI = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/'
    $managedDevices = (Invoke-RestMethod -Headers $header -Uri $URI -Method Get).value

    Authenticate using given application credentials.

    .EXAMPLE
    Connect-AzAccount

    $header = New-GraphAPIAuthHeader

    $URI = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/'
    $managedDevices = (Invoke-RestMethod -Headers $header -Uri $URI -Method Get).value

    Authenticate as current user.

    .EXAMPLE
    Connect-AzAccount

    $header = New-GraphAPIAuthHeader -useMSAL

    $URI = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/'
    $managedDevices = (Invoke-RestMethod -Headers $header -Uri $URI -Method Get).value

    Use MSAL for auth. token creation. Can help if token created by calling New-GraphAPIAuthHeader without any parameters (reusing existing AzureAD session) fails with 'forbidden' error when used.

    .EXAMPLE
    Connect-AzAccount

    $header = New-GraphAPIAuthHeader -useMSAL -scope 'https://graph.microsoft.com/Device.Read'

    $URI = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/'
    $managedDevices = (Invoke-RestMethod -Headers $header -Uri $URI -Method Get).value

    Use MSAL for auth. token creation. Can help if token created by calling New-GraphAPIAuthHeader without any parameters (reusing existing AzureAD session) fails with 'forbidden' error when used.

    .NOTES
    https://adamtheautomator.com/powershell-graph-api/#AppIdSecret
    https://thesleepyadmins.com/2020/10/24/connecting-to-microsoft-graphapi-using-powershell/
    https://github.com/microsoftgraph/powershell-intune-samples
    https://tech.nicolonsky.ch/explaining-microsoft-graph-access-token-acquisition/
    https://gist.github.com/psignoret/9d73b00b377002456b24fcb808265c23
    https://learn.microsoft.com/en-us/answers/questions/922137/using-microsoft-graph-powershell-to-create-script
    #>

    [Alias("New-IntuneAuthHeader", "Get-IntuneAuthHeader", "New-MgAuthHeader")]
    [CmdletBinding()]
    param (
        [System.Management.Automation.PSCredential] $credential,

        [ValidateNotNullOrEmpty()]
        [Alias("tenantId")]
        $tenantDomainName = $_tenantDomain,

        [switch] $useMSAL,

        [string[]] $scope,

        [int] $tokenLifeTime
    )

    #region checks
    if ($useMSAL) {
        Write-Verbose "Checking for MSAL.PS module..."
        if (!(Get-Module MSAL.PS) -and !(Get-Module MSAL.PS -ListAvailable)) {
            throw "Module MSAL.PS is missing. Function $($MyInvocation.MyCommand) cannot continue"
        }
    }

    if (!$credential -and !$useMSAL) {
        Write-Verbose "Checking for Az.Accounts module..."
        if (!(Get-Module Az.Accounts) -and !(Get-Module Az.Accounts -ListAvailable)) {
            throw "Module Az.Accounts is missing. Function $($MyInvocation.MyCommand) cannot continue"
        }
    }

    if ($tokenLifeTime -and (!$credential -or ($credential -and $useMSAL))) {
        Write-Warning "'tokenLifeTime' parameter will be ignored. It can be used only with 'credential' but without 'useMSAL' parameter."
    }

    if ($scope -and !$useMSAL) {
        Write-Warning "'scope' parameter will be ignored, because 'useMSAL' parameter is not used"
    }
    #endregion checks

    Write-Verbose "Getting token"

    if ($credential) {
        # use service principal credentials to obtain the auth. token

        Write-Verbose "Using provided application credentials"

        if ($useMSAL) {
            # authenticate using MSAL

            if (!$tenantDomainName) {
                throw "tenantDomainName parameter has to be set (something like contoso.onmicrosoft.com)"
            }

            $param = @{
                ClientId     = $credential.username
                ClientSecret = $credential.password
                TenantId     = $tenantDomainName
            }
            if ($scope) { $param.scopes = $scope }

            $token = Get-MsalToken @param

            if ($token.AccessToken) {
                $authHeader = @{
                    ExpiresOn     = $token.ExpiresOn
                    Authorization = "Bearer $($token.AccessToken)"
                }

                return $authHeader
            } else {
                throw "Unable to obtain token"
            }
        } else {
            # authenticate using direct API call

            $body = @{
                Grant_Type    = "client_credentials"
                Scope         = "https://graph.microsoft.com/.default"
                Client_Id     = $credential.username
                Client_Secret = $credential.GetNetworkCredential().password
            }

            Write-Verbose "Setting TLS 1.2"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            Write-Verbose "Connecting to $tenantDomainName"
            $connectGraph = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantDomainName/oauth2/v2.0/token" -Method POST -Body $body

            $token = $connectGraph.access_token

            if ($token) {
                if (!$tokenLifeTime) {
                    $tokenLifeTime = 60
                }

                $authHeader = @{
                    ExpiresOn     = (Get-Date).AddMinutes($tokenLifeTime - 10) # shorter by 10 minutes just for sure
                    Authorization = "Bearer $($token)"
                }

                return $authHeader
            } else {
                throw "Unable to obtain token"
            }
        }
    }

    if ($useMSAL) {
        # authenticate using MSAL as a current user

        Write-Verbose "Interactively as an user using MSAL"
        $param = @{
            ClientId = "14d82eec-204b-4c2f-b7e8-296a70dab67e" # 14d82eec-204b-4c2f-b7e8-296a70dab67e for 'Microsoft Graph PowerShell'
        }
        if ($tenantDomainName) { $param.TenantId = $tenantDomainName }
        if ($scope) { $param.scopes = $scope }

        $token = Get-MsalToken @param

        if ($token.AccessToken) {
            $authHeader = @{
                ExpiresOn     = $token.ExpiresOn
                Authorization = "Bearer $($token.AccessToken)"
            }

            return $authHeader
        } else {
            throw "Unable to obtain token"
        }
    } else {
        # get auth. token using the existing session created by the Connect-AzAccount command (from Az.Accounts PowerShell module)

        Write-Verbose "Non-interactively as an user using existing AzureAD session (created using Connect-AzAccount)"

        try {
            # test if connection already exists
            $azConnectionToken = Get-AzAccessToken -ResourceTypeName MSGraph -AsSecureString -ErrorAction Stop
            $token = [PSCredential]::New('dummy', $azConnectionToken.Token).GetNetworkCredential().Password

            # use AZ connection

            Write-Warning "Creating auth token from existing user ($($azConnectionToken.UserId)) session. If token usage ends with 'forbidden' error, use New-GraphAPIAuthHeader with 'useMSAL' parameter!"

            $authHeader = @{
                ExpiresOn     = $azConnectionToken.ExpiresOn
                Authorization = $token
            }

            return $authHeader
        } catch {
            throw "There is no active session to AzureAD. Call this function after Connect-AzAccount or use 'useMSAL' parameter or provide application credentials using 'credential' parameter."
        }
    }
}

Export-ModuleMember -function Expand-MgAdditionalProperties, Get-CodeGraphModuleDependency, Get-CodeGraphPermissionRequirement, Get-MgGraphAllPages, Invoke-GraphAPIRequest, New-GraphAPIAuthHeader

Export-ModuleMember -alias Get-CodeGraphPermission, Get-CodeGraphScope, Get-GraphAPICodeModuleDependency, Get-GraphAPICodePermission, Get-GraphAPICodeScope, Get-IntuneAuthHeader, Invoke-MgRequest, New-IntuneAuthHeader, New-MgAuthHeader
