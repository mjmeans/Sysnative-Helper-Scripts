# Written by: mjmeans 2023-06-27
#   Updated 2023-06-28
#     Added ability to -Verbose
#     Added support for binary values
#     Removed $file parameter. Just pipe output to Out-File 'filename.reg'
#   Updated 2023-06-29
#     Wrap binary key=value output to match reg export format

[cmdletbinding()]
param (
    $Regkey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing',
    $Like = '*.4650*',
    $Server = 'localhost'
)

$out = Invoke-Command -ComputerName $server -ArgumentList $regkey,$like -ScriptBlock {
    param ($regkey,$like)
    $VerbosePreference_original = $VerbosePreference
    $VerbosePreference = 'continue'
    Write-Verbose "Searching $regkey"
    Get-ChildItem $regkey -Recurse -Verbose | Where-Object {($_.Name -like $like)} | 
        foreach {
            $k = $_
            Write-Verbose "Processing key $k"
            Write-Output "`r`n[$k]"
            foreach ($p in $_.Property) {
                Write-Verbose "- Processing property $p"
                $v=$k.GetValue($p,$null)
                if ($v -ne $null) {
                    $t=$k.GetValueKind($p)
                    if ($t -eq 'String')
                        {Write-Output """$p""=""$($v -replace('\\','\\') -replace('\"','\"'))"""}
                    elseif ($t -eq 'Dword')
                        {Write-Output """$p""=dword:$("{0:x8}" -f $v)"}
                    elseif ($t -eq 'Binary')
                        {Write-Output (("""$p""=hex:"+(($v|ForEach-Object ToString X2) -join ',')) -replace '(^".{76},)|(.{74},)', "`$1`$2\`r`n  ")}
                    else {throw "unexpected registry value type: `n`r Key: $k`r`n Property: $p`r`n Type: $t`r`n Value: $v"}
                   # Write-Output """$p""=""
                }
            }
        } 
    }
Write-Verbose "Completed"
Write-Output "Windows Registry Editor Version 5.00"
Write-Output $out
