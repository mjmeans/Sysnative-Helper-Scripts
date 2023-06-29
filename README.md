# Sysnative-Helper-Scripts
Scripts I wrote to help with a server repair

Export-Reg.ps1 - Script to search the registry on the specified network computer for registry subkeys that match a pattern and output a *.reg format file.

## Usage:
    .\Export-Reg.ps1 -Server 'localhost' -Regkey 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Like '\*.4650\*'

Will search the server 'localhost' under the specified registry key for any keys that are like "\*.4650\*".

NOTES:
- This will display the resulting file to the output stream (console). To save it to a file pipe the stream to Out-File 'filename.reg'.

TODO:
- Make -Verbose selectable from the command line.
