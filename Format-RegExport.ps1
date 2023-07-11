<#
	.SYNOPSIS
	Contains the function Format-RegExport.

    .DESCRIPTION
    When imported into a PowerShell shell or into a script, allows the use of the Format-RegExport function.

	.EXAMPLE
    PS> #To import the function enter the following command
    PS> . .\Format-RegExport.ps1

#>

# Authot: mjmeans 2023-07-11
#
# CHANGE LOG
#
#   2023-07-11: mjmeans
#	  Created from refactoring out of Export-Registry.ps1
#
# KNOWN ISSUES
#
#   - Using Get-Item or Get-ChildItem to get a registry object will have the object name in the same casing as the specified path.
#     i.e. Get-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MICROSOFT' and Get-Item 'Registry::HKEY_LOCAL_MACHINE:\SOFTWARE\Microsoft'
#     will output different names. Make sure the passed registry object has the correct name casing before passing it to Format-RegExport.
#
# TO DO
#
#   - Verify that $InputObject is an actual registry key instead of something else
#
# NOTES
#
#   VALUES THAT CAN BE ENTERED USING THE REGEDIT GUI IN WINDOWS 10
#   (Windows Registry Editor Version 5.00)
#
#   PSValueKind  Win32 Type              RegFormat
#   ------------ ----------------------- ------------------------------------------------------------------------------------------------------------------------------------
#   String       REG_SZ                  ="<String value data with escape characters>"
#   Binary       REG_BINARY              =hex:<Binary data (as comma-delimited list of hexadecimal values)>
#   DWord        REG_DWORD               =dword:<DWORD value integer>
#   ExpandString REG_EXPAND_SZ           =hex(2):<Expandable string value data (as comma-delimited list of hexadecimal values representing a UTF-16LE NUL-terminated string)>
#   MultiString  REG_MULTI_SZ            =hex(7):<Multi-string value data (as comma-delimited list of hexadecimal values representing UTF-16LE NUL-terminated array of strings)>
#   QWord        REG_QWORD               =hex(b):<QWORD value (as comma-delimited list of 8 hexadecimal values, in little endian byte order)>
#                REG_DWORD_LITTLE_ENDIAN <Equivalent to REG_DWORD>
#                REG_QWORD_LITTLE_ENDIAN <Equivalent to REG_QWORD>
#
#   OTHER FORMATS WHICH CANNOT BE ENTERED USING THE REGEDIT GUI AND ARE NOT YET IMPLEMENTED HERE
#
#   PSValueKind  Win32 Typ               RegFormat
#   ------------ ----------------------- ------------------------------------------------------------------------------------------------------------------------------------
#                REG_NONE                =hex(0):<REG_NONE (as comma-delimited list of hexadecimal values)>
#                REGE_SZ                 =hex(1):<REG_SZ (as comma-delimited list of hexadecimal values representing a UTF-16LE NUL-terminated string)>
#                                        =hex(3):<Binary data (as comma-delimited list of hexadecimal values)> ; equal to "Value B"
#                REG_DWORD_LITTLE_ENDIAN =hex(4):<DWORD value (as comma-delimited list of 4 hexadecimal values, in little endian byte order)>
#                REG_DWORD_BIG_ENDIAN    =hex(5):<DWORD value (as comma-delimited list of 4 hexadecimal values, in big endian byte order)>
#                                        =hex(6):<unknown or undefined>
#                                        =hex(8):<REG_RESOURCE_LIST (as comma-delimited list of hexadecimal values)>
#                                        =hex(9):<unknown or undefined>
#                                        =hex(a):<REG_RESOURCE_REQUIREMENTS_LIST (as comma-delimited list of hexadecimal values)>
#                REG_LINK                =<unknown>:<A null-terminated Unicode string that contains the target path of a symbolic link that was created by calling the RegCreateKeyEx function with REG_OPTION_CREATE_LINK>

function Format-RegExport {
    <#
	    .Synopsis
	    Formats the output as a *.reg format compatible multi-line string.

	    .Description
	    The Format-RegKey cmdlet formats the output of a Get-Item or Get-ChildItem object containing a registry Subkey
        into a *.reg comptaible format.

	    .Parameter InputObject
	    The path to the registry key you want to export.

	    .Example
        Get-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion' | Format-RegExport

    #>

    [CmdletBinding()]
    Param (
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [object]$InputObject
    )

    ## Constants
    $crlf = "`r`n"

    $key = $InputObject
    $k = $key.Name

    Write-Verbose "Processing key $k"
    Write-Output "$crlf[$k]"
    foreach ($prop in $key.Property) {
	    Write-Verbose "- Processing property $prop"
        $p=$prop
        if ($prop -eq '(default)') {
            $v=$key.GetValue('',$null,'DoNotExpandEnvironmentNames')
            $p='@'
        } else {
            $v=$key.GetValue($prop,$null,'DoNotExpandEnvironmentNames')
            $p="`"$prop`""
        }
	    Write-Verbose "- Value is $v"
	    if ($v -ne $null) {
            if ($prop -eq '(default)') {
                $t=$key.GetValueKind('')
            } else {
                $t=$key.GetValueKind($prop)
            }
	        Write-Verbose "- Type is $t"
		    if ($t -eq 'String') {
                $pv = "$p=`"$($v -replace('\\','\\') -replace('\"','\"'))`""
                Write-Output $pv
            } elseif ($t -eq 'DWord') {
                $pv = "$p=dword:$("{0:x8}" -f $v)"
                Write-Output $pv
            } elseif ($t -eq 'QWord') {
                $a = [byte[]] -split (("{0:x16}" -f $v) -replace '..', '0x$& ')
                [array]::Reverse($a)
                $pv = "$p=hex(b):"+(($a|ForEach-Object ToString x2) -join ',')               
                Write-Output $pv
            } elseif ($t -eq 'Binary') {
                $pv = "$p=hex:"+(($v|ForEach-Object ToString x2) -join ',')
                $pv = ($pv -replace '((^.{76,78},)|(.{74,76},))', "`$1\`r`n  ")
                Write-Output $pv
            } elseif ($t -eq 'ExpandString') {
                $a = [System.Text.Encoding]::Unicode.GetBytes($v)
                $pv = "$p=hex(2):"+(($a|ForEach-Object ToString x2) -join ',') +',00,00'
                $pv = ($pv -replace '((^.{76,78},)|(.{74,76},))', "`$1\`r`n  ")
                Write-Output $pv
            } elseif ($t -eq 'MultiString') {
                $q = [System.String]::Join("`0",$v)
                $a = [System.Text.Encoding]::Unicode.GetBytes($q)
                $pv = "$p=hex(7):"+(($a|ForEach-Object ToString x2) -join ',') +',00,00,00,00'
                $pv = ($pv -replace '((^.{76,78},)|(.{74,76},))', "`$1\`r`n  ")
                Write-Output $pv
            } else {
                throw "unexpected registry value type: `n`r Key: $k`r`n Property: $p`r`n Type: $t`r`n Value: $v"
                # todo hex(7) type
                exit
            }
	    }
    }
}
