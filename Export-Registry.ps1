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
	# Export a *.reg file containing all keys under 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths' that match the wildcard string '*in*'.
    Export-Registry -RegKey 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths' -Like *in* -OutFile out.reg

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
#
# TEST
#    Import test file '_Test_Reg-Export.reg' into registry
#    PV> .\Export-Registry.ps1 -RegKey 'HKLM:\SOFTWARE\_Test' -Like '*Reg-Export*' -OutFile 'out.reg' -Verbose
#    Compare the '_Test_Reg-Export.reg' to the 'out.reg' file

[CmdletBinding()]
Param (
    [string]$RegKey = $(throw '-RegKey is required'),
    [string]$Like = '*',
    [string]$OutFile = $(throw '-OutFile is required')
)

## Includes
. .\Write-Log.ps1
. .\Format-RegExport.ps1

## Constants
$crlf = "`r`n"

## Verify before run
if (!(Test-Path -Path $RegKey -PathType Container))
{
    Write-Log -Level ERROR "PATH_NOT_FOUND: `"$RegKey`""
    Write-Log "The registry key specified by -RegKey <key> must exist."
    exit
}

$key = Get-Item $RegKey
$search = Join-Path $key $Like
Write-Log "Searching $search"
Write-Output 'Windows Registry Editor Version 5.00' | Out-File $OutFile -Encoding unicode

$keys = Get-ChildItem $Regkey -Recurse -Verbose | Where-Object {($_.Name -like $search)}
foreach ($k in $keys) {
    Format-RegExport -InputObject $k | Out-File $OutFile -Append -Encoding unicode    
} 


Write-Output "" | Out-File $OutFile -Append -Encoding unicode
Write-Log "Completed"
