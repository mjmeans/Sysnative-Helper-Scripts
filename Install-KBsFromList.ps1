[CmdletBinding()]
Param(
	[Parameter(position=0,mandatory=$true)]
	[string]$ListFile,
	[string]$KBPath = '.\',
	[switch]$Install
)

. .\Write-Log.ps1

Write-Verbose "ListFile=`"$ListFile`""
Write-Verbose "KBPath=`"$KBPath`""

$list = Get-Content $ListFile


if ($Install -ne $true) {
	Write-Log 'INFO: -Install switch not specified. Checking KBs exist only.'
}

foreach ($file in $list) {
	if ($file.trim() -eq '') {
	}
	elseif ($file.substring(0,1) -eq '-') {
		# do not process
	}
	elseif ($file.substring(0,1) -eq '#') {
		$comment = $file.substring(1)
		Write-Log INFO "$comment"
	}
	else {
		$filepath = Join-Path -Path $KBPath -ChildPath $file
		if ((Test-Path -Path $filepath -PathType Leaf) -eq $false) {
			Write-Log ERROR "FILE NOT FOUND `"$filepath`""
			# TODO: try to download it
		}
		else {
			if ($Install -eq $true) {
				$argumentList = "`"$filepath`" /quiet /norestart"
				$out = Start-Process -FilePath "wusa.exe" -ArgumentList $argumentList -Wait -PassThru -NoNewWindow
				if ($out.ExitCode -eq 0) { 
					Write-Log INFO "INSTALLED: `"$file`""
				}
				else { 
					Write-Log ERROR "Installation failed (0x$("{0:x8}" -f $out.ExitCode)) `"$file`""
				}
			}
		}
	}
}
