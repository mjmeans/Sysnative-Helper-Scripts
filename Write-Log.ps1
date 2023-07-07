
Function Write-Log {
    [CmdletBinding()]
    Param(
		[Parameter(Position=0,Mandatory=$False)]
		[string]
		$Message,
		
	    [Parameter(Mandatory=$False)]
		[ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
		[String]
		$Level = "INFO",

		[Parameter(Mandatory=$False)]
		[string]
		$logfile
    )

    $Stamp = (Get-Date).toString("yyyyMMdd_HHmmss.fff")
    $Line = "$Stamp`: $Level`: $Message"
    If($logfile) {
        Add-Content $logfile -Value $Line
    }
    Else {
        Write-Output $Line
    }
}
