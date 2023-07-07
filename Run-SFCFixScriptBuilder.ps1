    <#
	.Synopsis
	Runs SFCFixScriptBuilder.

	.Description
	Runs "SFCFixScriptBuilder.exe --components --full" with specified -Hive  and -ComponentsList
	to find registry values and create "SFCFixScript.txt" and "SFCFixScript.log".
	Also makes a timestamped copy of the created files.

	.Parameter RepairSourceHive
	The path to the source COMPONENTS hive to use to find the registry entries.

	.Parameter ComponentsList
	The path to the Missing_Components.txt or Corrupt_Components.txt output file created by Process-ComponentsScannerResults
	that lists the Components registry entries to look for in -Hive.
	Defaults to: Missing_Components.txt

	.Parameter ExcludeIdentity
	Exclude identity properties from the resulting SFCFixScript.txt file.
	
	.Parameter ExcludeS256H
    Exclude S256H properties from the resulting SFCFixScript.txt file.
	
	.Example
	# Create fix script for Missing_Components.txt.
	.\Run-SFCFixScriptBuilder.ps1 -Log ComponentsScanner.txt -Hive \\RepairSource\c$\Windows\System32\config\COMPONENTS

	# Create fix script for Corrupt_Components.txt exluding "identity" and "S256H keys.
	.\Run-SFCFixScriptBuilder.ps1 -Hive '\\repairserver\C$\Windows\System32\config\COMPONENTS' -ComponentsList .\Corrupt_Components.txt -ExcludeIdentity -ExcludeS256H
#>

[CmdletBinding()]
Param(
	[string]$RepairSourceHive = $(throw 'Must specify -RepairSourceHive <file> parameter.'),
	[string]$ComponentsList = 'Missing_Components.txt',
	[switch]$ExcludeIdentity,
	[switch]$ExcludeS256H,
	[string]$SysNativeToolsPath = '.\'
)

## Includes
. .\Write-Log.ps1

## Constants
$txtFile = "$($env:USERPROFILE)\Desktop\SFCFixScript.txt"
$logFile = '.\SFCFixScript.log'
$txtFileLocal = ".\SFCFixScript.txt"
$processName = 'SFCFixScriptBuilder.exe'

## Verify before run
$processPath = Join-Path -Path $SysNativeToolsPath -ChildPath $processName
if (!(Test-Path -Path $processPath -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$processPath`""
	Write-Log "Specify the location of the SysNative tools using -SysNativeToolPath <directory>"
    exit
}
if (!(Test-Path -Path $RepairSourceHive -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$RepairSourceHive`""
	Write-Log "Specify the location of the repair source hive using -RepairSourceHive <file>"
    exit
}
if (!(Test-Path -Path $ComponentsList -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$ComponentsList`""
	Write-Log "Specify the location of missing components list using -ComponentsList <file>"
    exit
}
if (Test-Path $txtFile -PathType leaf) { Remove-Item $txtFile }
if (Test-Path $logFile -PathType leaf) { Remove-Item $logFile }
if (Test-Path $txtFileLocal -PathType leaf) { Remove-Item $txtFileLocal }

## Run
$argumentList = "-hive `"$RepairSourceHive`" -log `"$ComponentsList`" --components --full"
Write-Log "Starting `"$processPath`" $argumentList"
$out = Start-Process -FilePath $processPath -ArgumentList $argumentList -Wait -PassThru -NoNewWindow -RedirectStandardOutput $logFile
if ($out.ExitCode -ne 0) { 
	Write-Log -Level ERROR "Process returned error $($out.ExitCode)"
	exit
}

if (Test-Path $txtFile -PathType leaf)
{
	Get-Item -Path $txtFile | Move-Item -Destination $txtFileLocal -Force
}
else
{
	Write-Log "$txtFile output from SFCFixScriptBuilder.exe not found"
	exit
}

if (($ExcludeIdentity) -or ($ExcludeS256H))
{
	$tmpFile = ".\SFCFixScriptTemp.txt"
	if (Test-Path $tmpFile -PathType leaf) { Remove-Item $tmpFile }
	$content = (Get-Content -Path $txtFileLocal)
	ForEach ($line in $content)
	{
		$key = ($line -split "=")[0]
		if ($ExcludeIdentity -and $key -eq '"identity"') {}
		elseif ($ExcludeS256H -and $key -eq '"S256H"') {}
		else { $line  | Out-file -FilePath $tmpFile -Append }
	}
	Remove-Item $txtFileLocal
	Rename-Item -Path $tmpFile -NewName $txtFileLocal
}

# Make a backup of the results in the current directory
$dt = (Get-Date).ToString('yyyyMMdd_HHmm')
$txtFileDt = ".\SFCFixScript_$dt.txt"
$logFileDt = ".\SFCFixScript_$dt.log"
Get-Item -Path $txtFileLocal | Copy-Item -Destination $txtFileDt
Get-Item -Path $logFile | Copy-Item -Destination $logFileDt

Write-Log 'Completed'