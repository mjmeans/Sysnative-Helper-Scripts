# Written by: mjmeans
param (
    $file = "searchresults.reg",
    $regkey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing',
    $like = '*.4650*',
    $server = 'repairserver'
)

$out = Invoke-Command -ComputerName $server -ArgumentList $file,$regkey,$like -ScriptBlock {
    param ($file,$regkey,$like)
    Get-ChildItem $regkey -Recurse | Where-Object {($_.Name -like $like)} |
        foreach {
            Write-Output "`r`n[$_]"
            foreach ($p in $_.Property) {
                $v=$_.GetValue($p); $t=$_.GetValueKind($p)
                if ($t -eq 'String') {$tv="""$($v -replace('\\','\\') -replace('\"','\"'))"""}
                elseif ($t -eq 'Dword') {$tv="dword:$("{0:x8}" -f $v)"}
                else {throw "unexpected registry value type: `n`r Key: $_`r`n Property: $p`r`n Type: $t`r`n Value: $v"}
                Write-Output """$p""=$tv"
            }
        }
    }
Write-Output "Windows Registry Editor Version 5.00" | Out-File $file
Write-Output $out | Out-File $file -Append