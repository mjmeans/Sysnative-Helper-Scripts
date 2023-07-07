[CmdletBinding()]
Param (
	[string]$ComponentsHive = "c:\windows\system32\config\components",
	[string]$SourceFile = "$($env:USERPROFILE)\Desktop\ComponentsScanner.txt",
	[string]$SysNativeToolsPath = '.\'
)

## Includes
. .\Write-Log.ps1

## Constants
$processName = 'RegRecover.exe'

## Verify before run
$processPath = Join-Path -Path $SysNativeToolsPath -ChildPath $processName
if (!(Test-Path -Path $processPath -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$processPath`""
	Write-Log "Specify the location of the SysNative tools using -SysNativeToolPath <directory>"
    exit
}
if (!(Test-Path -Path $SourceFile -PathType Leaf))
{
	Write-Log -Level ERROR "FILE_NOT_FOUND: `"$SourceFile`""
	Write-Log "Specify the location of the ComponentsScanner.txt file using -SourceFile <file>"
    exit
}

## Run
$argumentList = "-log `"$SourceFile`""
Write-Log "Starting `"$processPath`" $argumentList"
$out = Start-Process -FilePath $processPath -ArgumentList $argumentList -PassThru -Wait -NoNewWindow
if ($out.ExitCode -ne 0) {
    Write-Log -Level ERROR "Process exited with errorlevel $($out.ExitCode)"
    exit
}
Write-Log 'Completed'
