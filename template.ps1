### Demo ###
# A template file that can be used to build PowerShell demos

# import libDemo as a stand-alone file that is in the same directory as the demo script.
using module .\libDemo.psm1

# import libDemo installed as a module
#using module libDemo


# create the demo 
Initialize-Demo

#region
<#

Examples:

## SINGLE COMMAND ##
$command = @'

'@
Add-DemoCommand -Command $command -Comment 'A single command example'


## MULTISEGMENT COMMAND ##
$cmd1 = @'

'@
$cmd2 = @'

'@
$command = $cmd1, $cmd2
Add-DemoCommand -Segment $command -Comment 'A multisegment command example'


### FILE-BASED ###
# Split a file into segments by using adding this segment separator (nothing else but whitespace can be on the line): <###DEMO-BREAK###>
<#

$file = Get-Item "<path to>\powershellFile.ps1"
Add-DemoCommand -File $file -Comment "A File-type example. The file is auto-segmented using the break key-line."

#>
#endregion COMMANDS

# let the fun begin!
Start-Demo