<#
	.Synopsis
	Exports registry keys into *.reg files.

	.Description
	Exports registry keys into reg files without using reg.exe, and optionally filters the results.

	.Parameter RegKey
	The path to the registry key you want to export.

	.Parameter Like
	The -Like filter to use to filter exported keys.
    Default '*'

	.Parameter OutFile
	The path to the output *.reg file you want to create. This will overwrite the file without warning.
	
	.Example
	# Export a *.reg file containing all keys under 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' that match the wildcard string '*.4650_*'.
    Export-Registry -RegKey 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Like *.4650_* -OutFile out.reg

#>

# Authot: mjmeans 2023-06-27
#
# Change log
#   2023-06-28: mjmeans
#	  Added ability to -Verbose
#	  Added support for binary values
#	  Removed $file parameter. Just pipe output to Out-File 'filename.reg'
#   2023-06-29: mjmeans
#	  Wrap binary key=value output to match reg export format
#   2023-07-06: mjmeans
#	  Added Write-Log
#     Added support for (default) @
#     Removed the ability to invoke the script on a remove computer
#
# TO DO
#    Add remote option back in
#    Verify that $RegKey is an actual registry key instead of something else

[CmdletBinding()]
Param (
    [string]$RegKey = $(throw '-RegKey is required'),
    [string]$Like = '*',
    [string]$OutFile = $(throw '-OutFile is required')
)

## Includes
. .\Write-Log.ps1

## Constants
$crlf = "`r`n"

## Verify before run
if (!(Test-Path -Path $RegKey -PathType Container))
{
    Write-Log -Level ERROR "PATH_NOT_FOUND: `"$RegKey`""
    Write-Log "The registry key specified by -RegKey <key> must exist."
    exit
}

Write-Log "Searching $(Join-Path $RegKey $Like)"
Write-Output 'Windows Registry Editor Version 5.00' | Out-File $OutFile

$key = Get-Item $RegKey
Write-Output "$crlf[$key]" | Out-File $OutFile -Append

$keys = Get-ChildItem $Regkey -Recurse -Verbose | Where-Object {($_.Name -like (Join-Path $key $Like))}
foreach ($k in $keys) {
    Write-Verbose "Processing key $k"
    Write-Output "$crlf[$k]" | Out-File $OutFile -Append
    foreach ($prop in $k.Property) {
	    Write-Verbose "- Processing property $prop"
        $p=$prop
        if ($prop -eq '(default)') {
            $v=$k.GetValue('',$null,"DoNotExpandEnvironmentNames")
            $p='@'
        } else {
            $v=$k.GetValue($prop,$null,"DoNotExpandEnvironmentNames")
            $p="`"$prop`""
        }
	    Write-Verbose "- Value is $v"
	    if ($v -ne $null) {
            if ($prop -eq '(default)') {
                $t=$k.GetValueKind('')
            } else {
                $t=$k.GetValueKind($prop)
            }
		    if ($t -eq 'String') {
                $pv = "$p=`"$($v -replace('\\','\\') -replace('\"','\"'))`""
                Write-Output $pv | Out-File $OutFile -Append
            } elseif ($t -eq 'Dword') {
                $pv = "$p=dword:$("{0:x8}" -f $v)"
                Write-Output $pv | Out-File $OutFile -Append
            } elseif ($t -eq 'Binary') {
                $pv = "$p=hex:"+(($v|ForEach-Object ToString x2) -join ',')
                $pv = ($pv -replace '((^.{76,78},)|(.{74,76},))', "`$1\`r`n  ")
                Write-Output $pv | Out-File $OutFile -Append
            } elseif ($t -eq 'ExpandString') {
                $a = [System.Text.Encoding]::Unicode.GetBytes($v)
                $pv = "$p=hex(2):"+(($a|ForEach-Object ToString x2) -join ',') +',00,00'
                $pv = ($pv -replace '((^.{76,78},)|(.{74,76},))', "`$1\`r`n  ")
                Write-Output $pv | Out-File $OutFile -Append
            } else {
                throw "unexpected registry value type: `n`r Key: $k`r`n Property: $p`r`n Type: $t`r`n Value: $v"
                # todo hex(7) type
                exit
            }
	    }
    }
} 

Write-Output "" | Out-File $OutFile -Append
Write-Log "Completed"
