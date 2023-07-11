# Sysnative-Helper-Scripts
Scripts I wrote to help with a server repair

Export-Registry.ps1 - A script to search the registry for all subkeys that match a pattern and output a \*.reg format file.
Format-RegExport.ps1 - A dot include script containing the function Format-RegExport which takes registry object passed to it's input stream and outputs a stream of that key and it's values formatted in the \*.reg file format. 

# (The below scripts are broken since Export-Registry was refactored)

Export-Reg.ps1 - (broken since Export-Registry was refactored) Script to search the registry on the specified network computer for registry subkeys that match a pattern and output a \*.reg format file.

## Usage:
    .\Export-Reg.ps1 -Server 'localhost' -Regkey 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Like '\*.4650\*'

Will search the server 'localhost' under the specified registry key for any keys that are like "\*.4650\*" and output a \*.reg format file. 

NOTES:
- This will display the resulting file to the output stream (console). To save it to a file pipe the stream to Out-File 'filename.reg'.

TODO:
- Make -Verbose selectable from the command line.
