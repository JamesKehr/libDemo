### DemoDemoDemo ###
# This is an example of how to use each of the three demo types. This file only exists on the GitHub repo.

# import libDemo as a stand-alone file that is in the same directory as the demo script.
using module .\libDemo.psm1

# import libDemo installed as a module
#using module libDemo


# create the demo 
Initialize-Demo

#region COMMANDS
$command = @'
Get-Process | Where-Object Name -eq "pwsh"
#
# the same as:
# Get-Process | ForEach-Object { if ($_.Name -eq "pwsh") { $PSItem } }
#
# But easier to type...
'@
Add-DemoCommand -Command $command -Comment 'Command-type demo. No animations or fancy scrolling.'


$command1 = @'
class FunnyMath {
   [int]
   $Num1

   [int]
   $Num2

   FunnyMath($n1, $n2) {
      $this.Num1 = $this.ValidateInteger($n1)
      $this.Num2 = $this.ValidateInteger($n2)
   }

'@

$command2 = @'
   [int]
   ValidateInteger($num) {
      [int]$pNum = 0

      # TryParse returns true when parsing is successful, false when it fails.
      if ( -NOT [int]::TryParse($num, [ref]$pNum) ) {
         throw "$num is not an integer."
      }

      return $pNum
   }

'@

$command3 = @'
   [int]Add() {
      return ($this.Num1 + $this.Num2)
   }

   [int]Subtract() {
      return ($this.Num1 - $this.Num2)
   }

   [int]Multiply() {
      if (($this.Num1 -eq 6 -and $this.Num2 -eq 9) -or
           ($this.Num1 -eq 9 -and $this.Num2 -eq 6) ) {
         return 42
      }
      return ($this.Num1 * $this.Num2)
   }

   [int]Divide() {
      return ($this.Num1 / $this.Num2)
   }
}
'@

$command4 = @'
$e4 = [FunnyMath]::new(42,6)
Write-Host "Add: $($e4.Add())"
Write-Host "Subtract: $($e4.Subtract())"
Write-Host "Divide: $($e4.Divide())"

$e4_2 = [FunnyMath]::new(9,6)
Write-Host "Multiply: $($e4_2.Multiply())"
'@
[string[]]$command = $command1, $command2, $command3, $command4 
Add-DemoCommand -Segment $command -Comment 'A Segment-type example. Command in many parts, but run as a single command.'


# add a file based demo
$file = Get-Item "$PSScriptRoot\Start-MyFirstScript.ps1"
#$file = Get-Item "$PSScriptRoot\libDemo.psm1" # this will highlight but fail execution. This is good for testing.
Add-DemoCommand -File $file -Comment "A File-type example. The file is auto-segmented and presented."

#endregion COMMANDS

# let the fun begin!
Start-Demo