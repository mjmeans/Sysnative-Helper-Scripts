[CmdletBinding()]
Param(
	[string]$Script = "SFCFixScript.txt",
	[string]$SysNativeToolsPath = '.\',
)

## Includes
. .\Write-Log.ps1

## Constants
$processName = 'ComponentsScanner.exe'

## Verify before run
$processPath = Join-Path -Path $SysNativeToolsPath -ChildPath $processName
if (!(Test-Path -Path $processPath -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$processPath`""
	Write-Log "Specify the location of the SysNative tools using -SysNativeToolPath <directory>"
    exit
}

## Run
$argumentList = "`"$Script`""
Write-Log "Starting `"$processPath`" $argumentList"
$out = Start-Process -FilePath $processPath -ArgumentList $argumentList -Wait -PassThru -NoNewWindow -RedirectStandardOutput $logFile
if ($out.ExitCode -ne 0) { 
	Write-Log -Level ERROR "Process returned error $($out.ExitCode)"
	exit
}

# Move output file to local directory and make a backup of the results in the current directory
$dt = (Get-Date).ToString('yyyyMMdd_HHmm')
$txtPath = "$($env:USERPROFILE)\Desktop\SFCFix.txt"
$txtPathLocal = ".\SFCFix.txt"
$logPathDt = ".\SFCFix_$dt.log"

Get-Item -Path $txtPath | Move-Item -Destination $txtPathLocal
Get-Item -Path $txtPathLocal | Copy-Item -Destination $logPathDt

Write-Log 'Completed'
