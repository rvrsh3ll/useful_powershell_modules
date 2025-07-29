﻿function Quote-String {
    <#
    .SYNOPSIS
    Function for splitting given text by delimiter and enclosing the resulting items into quotation marks.

    .DESCRIPTION
    Function for splitting given text by delimiter and enclosing the resulting items into quotation marks.

    Input can be taken from pipeline, parameter or clipboard.

    Result can be returned into console or clipboard. Can be returned joined (as string) or as array.

    .PARAMETER string
    Optional parameter.
    String(s) that should be split and enclosed by quotation marks.

    If none is provided, clipboard content is used.

    .PARAMETER delimiter
    Delimiter value.

    Default is ','.

    .PARAMETER joinUsing
    String that will be used to join the resultant items.

    Default is value in 'delimiter' parameter.

    .PARAMETER outputToConsole
    Switch for outputting result to the console instead of clipboard.

    .PARAMETER dontJoin
    Switch for omitting final join operation.
    When 'outputToConsole' is used, you will get array.
    When 'outputToConsole' is NOT used, clipboard will contain string with quoted item per line.

    .PARAMETER quoteBy
    String that will be used to enclose resultant items.

    Default is '.

    .EXAMPLE
    Quote-String -string "John, Amy"

    Result (saved into clipboard) will be quoted strings joined by comma: 'John', 'Amy'

    .EXAMPLE
    (image that clipboard contains string "John, Amy")

    Quote-String

    Result (saved into clipboard) will be quoted strings joined by comma: 'John', 'Amy'

    .EXAMPLE
    Quote-String -string "John, Amy" -outputToConsole -joinUsing ";"

    Result (in console) will be quoted strings joined by semicolon:
    'John';'Amy'

    .EXAMPLE
    "John", "Amy" | Quote-String -outputToConsole -dontJoin

    Result (in console) will be array containing quoted strings:
    'John'
    'Amy'
    #>

    [CmdletBinding()]
    [Alias("ConvertTo-QuotedString")]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]] $string,

        [string] $delimiter = ",",

        [string] $joinUsing,

        [switch] $outputToConsole,

        [switch] $dontJoin,

        [string] $quoteBy = "'"
    )

    if (!$joinUsing -and !$dontJoin) {
        $joinUsing = $delimiter
    }

    # I need to take pipeline input as a whole (because of final save into clipboard)
    if ($Input) {
        Write-Verbose "Using automatic variable 'Input' content"
        $string = $Input
    }

    if (!$string) {
        Write-Verbose "Using clipboard content"
        $string = Get-Clipboard -Raw
    }
    if (!$string) {
        throw "'String' parameter and even clipboard are empty."
    }

    Write-Verbose "'String' parameter contains:`n$string"

    if ($delimiter -eq "`n") {
        # sometimes `n generates weird results, because `r`n is needed
        $result = $string.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    } else {
        $result = $string.Split($delimiter, [StringSplitOptions]::RemoveEmptyEntries)
    }
    $result = $result | % {
        $quoteBy + $_.trim() + $quoteBy
    }

    if ($outputToConsole) {
        if ($joinUsing) {
            $result -join $joinUsing
        } else {
            $result
        }
    } else {
        Write-Warning "Result was copied to clipboard"
        if ($joinUsing) {
            Set-Clipboard ($result -join $joinUsing)
        } else {
            Set-Clipboard $result
        }
    }
}