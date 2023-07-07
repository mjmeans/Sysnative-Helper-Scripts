[CmdletBinding()]
Param(
	[string]$SourceFile = "$($env:USERPROFILE)\Desktop\ComponentsScanner.txt",
	[switch]$ExcludeCorruptValueData,
	[switch]$ExcludeMissingRegistryKeys
)

## Includes
. .\Write-Log.ps1

## Constants
$cwd = ".\"

If (!(Test-Path $SourceFile -PathType leaf))
{
	throw("-SourceFile must specify a file, such as .\ComponentsScanner.txt'")
}

$inFile = $SourceFile
$corruptComponentsFileBaseName = "Corrupt_Components"
$missingComponentsFileBaseName = "Missing_Components"
$dt = (Get-Date).ToString('yyyyMMdd_HHmm')

if (!$ExcludeCorruptValueData) {
	# Search "==== Corrupt Value Data ====" section for keys to copy to "Corrupt_Components.txt"
	$fromHere = (Select-String -Path $inFile -Pattern '==== Corrupt Value Data ====' | Select-Object LineNumber).LineNumber
	$toHere = (Select-String -Path $inFile -Pattern '==== Repair Log ====' | Select-Object LineNumber).LineNumber - 1
	$suggested = (Get-Content -Path $inFile | Select-Object -Index ($fromHere..$toHere) | Select-String -Pattern 'Key:')
	If ($suggested -ne "")
	{
		$outFile = "$cwd$corruptComponentsFileBaseName.txt"
		$outFileDt = "$cwd$($corruptComponentsFileBaseName)_$dt.txt"
		If (Test-Path $outFile -PathType leaf) { Remove-Item $outFile }
		$i = 0
		# found some
		ForEach ($line in $suggested)
		{
			($line -split "\\")[3] | Out-file -FilePath $outFile -Append
			$i++
		}
		if ($i -ne 0)
		{
			Write-Log "$i Corrupt Value Data exported to $outFile"
			If (Test-Path $outFile -PathType leaf) { Get-Item $outFile | Copy-Item -Destination $outFileDt}
    		Write-Log "... and to $outFileDt"
			Write-Log "Correct corrupt identity values with Run-RegRecover"
		}
	}
}

if (!$ExcludeMissingRegistryKeys) {
	# Search "== Missing Registry Keys ==" for DerivedData keys to copy to "Missing_Components.txt"
	$fromHere = (Select-String -Path $inFile -Pattern '== Missing Registry Keys ==' | Select-Object LineNumber).LineNumber
	$toHere = (Select-String -Path $inFile -Pattern 'Storing ' | Select-Object LineNumber).LineNumber - 1
	$suggested = (Get-Content -Path $inFile | Select-Object -Index ($fromHere..$toHere) | Select-String -Pattern 'DerivedData\\')
	If ($suggested -ne "")
	{
		$outFile = "$cwd$missingComponentsFileBaseName.txt"
		$outFileDt = "$cwd$($missingComponentsFileBaseName)_$dt.txt"
		If (Test-Path $outFile -PathType leaf) { Remove-Item $outFile }
		$i = 0
		# found some
		ForEach ($line in $suggested)
		{
			($line -split "\ ")[2] | Out-file -FilePath $outFile -Append
			$i++
		}
		Write-Log "$i Missing Registry Keys exported to $outFile"
		If (Test-Path $outFile -PathType leaf) { Get-Item $outFile | Copy-Item -Destination $outFileDt}
		Write-Log "... and to $outFileDt"
		Write-Log "Correct missing registry keys with Run-SFCFixScriptBuilder and then Run_SFCFix -Script"
	}
}

Write-Log 'Completed'