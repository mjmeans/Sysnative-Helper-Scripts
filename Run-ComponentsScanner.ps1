[CmdletBinding()]
Param (
	[string]$SysNativeToolsPath = '.\'
)

## Includes
. .\Write-Log.ps1

## Constants
$outFileBaseName = "ComponentsScanner"
$txtPath = "$($env:USERPROFILE)\Desktop\"
$logPath = "$($env:LOCALAPPDATA)\Sysnative\"
$cwd = ".\"
$missingComponentsFileBaseName = 'Missing_Components'
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
$processPath = Join-Path -Path $SysNativeToolsPath -ChildPath $processName
Write-Log "Starting `"$processPath`""
$out = Start-Process -FilePath $processPath -PassThru -Wait -NoNewWindow
if ($out.ExitCode -ne 0) {
    Write-Log "Process exited with errorlevel $($out.ExitCode)"
    exit
}

## copy results to CWD and make a timstamped copys
$dt = (Get-Date).ToString('yyyyMMdd_HHmm')
$path = "$txtPath$outFileBaseName.txt"
If (Test-Path $path -PathType leaf)
{
	Get-Item $path | Copy-Item -Destination "$cwd$($outFileBaseName)_$dt.txt"
	Get-Item $path | Copy-Item -Destination "$cwd$outFileBaseName.txt" -Force
}
$path = "$logPath$outFileBaseName.log"
If (Test-Path $path -PathType leaf)
{
	Get-Item $path | Copy-Item -Destination "$cwd$($outFileBaseName)_$dt.log"
	Get-Item $path | Copy-Item -Destination "$cwd$outFileBaseName.log" -Force
}
