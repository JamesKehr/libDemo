#requires -Version 7

using namespace System.Collections.Generic


<#
Workflow:
┌──────────────────────────────────────────────────────────────────────────────────┐ 
│[Demo]                                                                            │ 
│                                                                                  │ 
│     [List[DemoSegment]]- A [Demo] contains one or more segment. A segment is     │ 
│                                                                                  │ 
│                         all or some of the commands in a demo.                   │ 
│                                                                                  │ 
│                                                                                  │ 
└──────────────────────────────────────────────────────────────────────────────────┘ 
                                                                                     
                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────┐ 
│ [DemoSegment]                                                                    │ 
│                                                                                  │ 
│    [List[DemoLine]] - A [DemoSegment] containes one or more line. A line is a    │ 
│                                                                                  │ 
│                       command or comment of the demo.                            │ 
│                                                                                  │ 
│                                                                                  │ 
└──────────────────────────────────────────────────────────────────────────────────┘ 
                                                                                     
                                                                                     
┌──────────────────────────────────────────────────────────────────────────────────┐ 
│[DemoLine] - A [DemoLine] contains the pre-highlighted and raw line, and stats.   │ 
│                                                                                  │ 
│    RawLine - The unmodified line.                                                │ 
│                                                                                  │ 
│    HighlightedLine - The pre-highlighted line using ASCII escape codes.          │ 
│                                                                                  │ 
└──────────────────────────────────────────────────────────────────────────────────┘ 
                                                                                     
 The demo command is created by merging the segments together and running the command
 as a scriptblock. Unless a file is used, in which case the file is executed in the  
 same window as the demo.


 [DemoHighlightColor] adds the ability to change the highlighter colors at the cost
 of requiring a reprocess of lines post-color change. This is because all of the highlights
 are pre-processed to improve animation performance. The reprocessing performance penalty 
 is offset by not reprocessing the line highlights, by default. Use "Set-DemoColor" with 
 "-Update" on the last color change to reprocess the lines.

All colors use ANSI/ASCII escape sequences. See the two article below if you are unfamiliar.

https://duffney.io/usingansiescapesequencespowershell/
https://en.wikipedia.org/wiki/ANSI_escape_code#Colors


TO-DO:

- Optimize highlighting so not every char is highlighted when not needed (such as whole words) - ONGOING

FUTURE:

- Here-strings do not work correctly. This is a known issue that needs to be addressed in a future version. This can be handled similarly to multi-line comments (MLC).

- Dynamically build the [DemoApprovedVerbs] and [DemoApprovedVerbsFirstLetter] enums.


NOTES:

- Highlighting is performed one line at a time. This means certain multi-line capabilities like comments and here-strings (@''@ or @""@") need some special attention.
- Statements like if, switch, while, do, for, foreach, etc. MUST have any statement syntax, like the opening squiggly brackets ({), on the same line; otherwise, 
   the regex patterns used to match and highlight the statement will fail.
- 



#>

<###DEMO-BREAK###>

# single or double quotes
enum DemoQuoteType {
    Disable
    Single
    Double
}

<#

# get a list of approved verbs
# https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.4
$verbs = [System.Collections.Generic.List[string]]::new()
$verbs.AddRange([string[]]([System.Management.Automation.VerbsCommon].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsCommunications].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsData].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsDiagnostic].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsLifeCycle].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsSecurity].GetFields().Name))
$verbs.AddRange([string[]]([System.Management.Automation.VerbsOther].GetFields().Name))
$verbs = $verbs | Sort-Object -Unique

# add the missing pipeline verbs
$verbs += "Foreach"
$verbs += "Where"
$verbs += "Sort"

@"
enum DemoApprovedVerbs {
$($verbs | foreach-object {"`t$_`n"})}
"@

@"
enum DemoApprovedVerbsFirstLetter {
$($verbs | foreach-object {$_[0]} | Sort-Object -Unique | Foreach-Object {"`t$_`n"})}
"@

#>


enum DemoApprovedVerbs {
    Add
    Approve
    Assert
    Backup
    Block
    Build
    Checkpoint
    Clear
    Close
    Compare
    Complete
    Compress
    Confirm
    Connect
    Convert
    ConvertFrom
    ConvertTo
    Copy
    Debug
    Deny
    Deploy
    Disable
    Disconnect
    Dismount
    Edit
    Enable
    Enter
    Exit
    Expand
    Export
    Find
    ForEach
    Format
    Get
    Grant
    Group
    Hide
    Import
    Initialize
    Install
    Invoke
    Join
    Limit
    Lock
    Measure
    Merge
    Mount
    Move
    New
    Open
    Optimize
    Out
    Ping
    Pop
    Protect
    Publish
    Push
    Read
    Receive
    Redo
    Register
    Remove
    Rename
    Repair
    Request
    Reset
    Resize
    Resolve
    Restart
    Restore
    Resume
    Revoke
    Save
    Search
    Select
    Send
    Set
    Show
    Skip
    Sort
    Split
    Start
    Step
    Stop
    Submit
    Suspend
    Switch
    Sync
    Test
    Trace
    Unblock
    Undo
    Uninstall
    Unlock
    Unprotect
    Unpublish
    Unregister
    Update
    Use
    Wait
    Watch
    Where
    Write
}

# this covers both statements and verbs
enum DemoApprovedVerbsFirstLetter {
    A
    B
    C
    D
    E
    F
    G
    H
    I
    J
    L
    M
    N
    O
    P
    R
    S
    T
    U
    W
}

enum DemoLineColoring {
    Solid
    Syntax
}

enum DemoLineType {
    None
    FadeIn1
    FadeIn2
    FadeIn3
    Print
    FadeOut1
    FadeOut2
    FadeOut3
}

<#
Single = The demo is in a single string
Multi = The demo is broken up between multiple segments
#>
enum DemoType {
    Disable
    Single
    Multi
    File
}

enum DemoHighlightColor {
    Variable   
    Loop       
    LoopControl
    Comment    
    Equal      
    Parameter  
    Quote      
    Command    
    DataType   
    Default    
}

<###DEMO-BREAK###>

# stores the colors used by the highlighter(s)
# colors must be in ASCII escape codes
# example color palette:
# https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
class DemoColor {
    #region PROPERTIES
    [string]
    $Variable

    [string]
    $Loop

    [string]
    $LoopControl

    [string]
    $Comment

    [string]
    $Equal

    [string]
    $Parameter

    [string]
    $Quote

    [string]
    $Command

    [string]
    $DataType

    [string]
    $Default
    #endregion PROPERTIES

    DemoColor() {
        $this.Variable    = "`e[38;2;0;255;0m"
        $this.Loop        = "`e[38;2;92;92;255m"
        $this.LoopControl = "`e[38;2;180;23;158m"
        $this.Comment     = "`e[38;2;0;128;0m"
        $this.Equal       = "`e[90m"
        $this.Parameter   = "`e[90m"
        $this.Quote       = "`e[36m"
        $this.Command     = "`e[38;2;249;241;165m"
        $this.DataType    = "`e[38;5;128m"
        $this.Default     = "`e[37m"
    }
    #endregion

    #region METHODS
    # updates a highlighter color
    SetColor([DemoHighlightColor]$colorName, [string]$color) {
        # add the escape character if it's missing
        if ($color -notmatch "`e") {
            $color = [string]::Concat("`e", $color)
        }

        ## this regex validates the escape character format
        ## 3 modes are supported: 3/4-bit (\d{2,3}), 8-bit (38;5;$rgxByteRange), and 24-bit (RGB) (38;2(;$rgxByteRange){3})
        # matches numbers 0..255
        [regex]$rgxByteRange = "([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])"
        # matches 3 types of ASCII escape color sequences
        [regex]$rgxAsciiColor = "^\e\[(\d{2,3}|38;2(;$rgxByteRange){3}|38;5;$rgxByteRange)m"

        # set the color if the format is the format is correct
        if ( $color -match $rgxAsciiColor ) {
            $this."$colorName" = $color
        } else {
            throw "ERROR: Invalid color! Colors must be an ASCII escape foreground color. See: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors"
        }
    }

    # get one color
    [string]
    GetColor([DemoHighlightColor]$color) {
        return $this."$color"
    }

    # Get the color by name
    [string]
    GetVariableColor() { return $this.Variable }

    [string]
    GetLoopColor() { return $this.Loop }

    [string]
    GetLoopControlColor() { return $this.LoopControl }

    [string]
    GetCommentColor() { return $this.Comment }

    [string]
    GetEqualColor() { return $this.Equal }

    [string]
    GetParameterColor() { return $this.Parameter }

    [string]
    GetQuoteColor() { return $this.Quote }

    [string]
    GetCommandColor() { return $this.Command }

    [string]
    GetDataTypeColor() { return $this.DataType }

    [string]
    GetDefaultColor() { return $this.Default }

    # returns all colors as a PSCustomObject
    [PSCustomObject]
    GetAllColorsVisible() {
        $names = [DemoHighlightColor].GetEnumNames()
        $tmp = [PSCustomObject]@{}

        $names | & {process { $tmp | Add-Member -MemberType NoteProperty -Name $_ -Value "$([regex]::Escape($this."$_"))" }}

        return $tmp
    }

    # the escape character prevents the color text from printing, so this method regex escape to create a printable string
    [string]
    GetColorVisible([DemoHighlightColor]$colorName) {
        return "$([regex]::Escape($this."$colorName"))"
    }
    
    [string]
    ToString() {
        $names = [DemoHighlightColor].GetEnumNames()
        $longestName = 0
        $names | ForEach-Object {
            if ($_.Length -gt $longestName) {
                $longestName = $_.Length
            }
        }

        return @"
$($names | & {process {"$($_.PadRight($longestName, " ")) : $([regex]::Escape($this."$_"))`n"}})
"@
    }

    # prints the color name and visible color sequence in the sequence color
    WritePrettyString() {
        $names = [DemoHighlightColor].GetEnumNames()
        $longestName = 0
        $names | ForEach-Object {
            if ($_.Length -gt $longestName) {
                $longestName = $_.Length
            }
        }

        $names | & {process { [System.Console]::WriteLine("$($this."$_")$($_.PadRight($longestName, " ")) : $([regex]::Escape($this."$_"))`e[0m")}}
    }
    #endregion METHODS
}

<###DEMO-BREAK###>

# performs PowerShell syntax highlighting
class DemoHighlightPowerShell {
    [string]
    $RawLine

    [DemoColor]
    $SyntaxColor

    DemoHighlightPowerShell() {
        $this.RawLine     = $null
        $this.SyntaxColor = [DemoColor]::new()
    }

    DemoHighlightPowerShell([string]$ln) {
        $this.RawLine     = $ln
        $this.SyntaxColor = [DemoColor]::new()
    }

    # this method is standardized in case this library eventually handles multiple syntax types
    [string]
    HighlightLine([string]$line) {
        return ($this.HighlightLinePowerShell($line))
    }

    # highlights one line of PowerShell code, where multi-line comment is always false
    [string]
    HighlightLinePowerShell([string]$line) {
        return ($this.HighlightLinePowerShell($line, $false))
    }

    # highlights one line of PowerShell code, with an optional multi-line comment switch
    [string]
    HighlightLinePowerShell([string]$line, [bool]$EnableMLC) {
        # convert the command to chars
        $cmdChars = $line.ToCharArray()

        # colorized string
        $glStr = ''

        # gets verb names and verb first letters
        $verbs = [System.Enum]::GetValues([DemoApprovedVerbs])
        $verbsFL = [System.Enum]::GetValues([DemoApprovedVerbsFirstLetter])

        # create the regex for approved verbs
        # search only from the beginning of the line 
        [regex]$rgxVerbs = "^(?<cl>{0}-\w+)" -f ($verbs -join '-\w+)|^(?<cl>')

        # create a regex for the first letter of approved verbs
        [regex]$rgxVerbsFL = "$($verbsFL -join '|')"

        # regex for statements and loops
        # search only from the beginning of the line 
        $statements = "if", "while", "do", 
                        "until", "switch", "for", 
                        "foreach", "try", "catch", 
                        "finally", "begin", "process", 
                        "end", "else", "elseif"
        $tmpRgx =  '^(?<st>{0})\s*' -f ($statements -join ')\s*(\(|\{|\[.*\]\s*\{)|^(?<st>')
        $tmpRgx = [string]::Concat($tmpRgx, '(\(|\{|\[.*\]\s*\{)')
        [regex]$rgxStatement = $tmpRgx

        # regex for loop control: break and continue
        # this is tricky because a loop name can come after the command
        [regex]$rgxLoopCtrl = "^(?<lc>break|continue|default|return|class)(\s*|\s+\w+|\s*\}\s*)"

        [regex]$rgxFunction = "^(?<st>function|class|enum)\s+.*\s*\{"

        # regex to find a word
        [regex]$rgxFndWord = "^(?<word>\w+-?\w+)\s*"
        
        # regex to find text inside data type brackets
        [regex]$rgxFndDTWord = "^(?<word>.*)(\[|\])"

        # controls the lookahead by getting the length of the longest verb
        #$theLongestVerb = $verbs | ForEach-Object { $_.ToString().Length } | Measure-Object -Maximum | ForEach-Object Maximum

        # colors in ASCII escape codes
        # https://i.sstatic.net/9UVnC.png
        $varColor   = $this.SyntaxColor.GetVariableColor()
        $loopColor  = $this.SyntaxColor.GetLoopColor()
        $lpCtlColor = $this.SyntaxColor.GetLoopControlColor()
        $cmtColor   = $this.SyntaxColor.GetCommentColor()
        $eqColor    = $this.SyntaxColor.GetEqualColor()
        $paramColor = $this.SyntaxColor.GetParameterColor()
        $quoteColor = $this.SyntaxColor.GetQuoteColor()
        $cmdColor   = $this.SyntaxColor.GetCommandColor()
        $dtColor    = $this.SyntaxColor.GetDataTypeColor()
        $dfltColor  = $this.SyntaxColor.GetDefaultColor()
        
        # tracks whether the text is inside quotes
        $inQuotes = $false
        [DemoQuoteType]$quoteType = "Single"

        # used to color the variable
        $inVar = $false

        # used to color a data type
        $inDT = $false
        $dtLevel = 0

        # track sub-expressions
        $inSubExp = $false

        # used to color parameters
        $inParam = $false

        # tracks the char number for look ahead
        $charNum = 0

        # next color, for situations where there is no good way to end a color scheme
        # nextColor = "Fred" turns off nextColor
        $nextColor = "Fred"

        # how long to maintain the color
        $nextColorLen = 0

        # uses NextColor instead of ignoring it
        $nextColorForce = $false

        # control multiline highlighting
        #[regex]$rgxMLCStart = "<#"
        #[regex]$rgxMLCEnd = "#>"
        $inMLC = $EnableMLC

        # write the text
        foreach ($char in $cmdChars) {
            # assign the default color here
            $color = $dfltColor
            if ($nextColor -ne "Fred" -and $nextColorLen -le 0) {
                #if ($inMLC) { "Still in MLC - end of next ($($cmdChars[$charNum]))" >> C:\temp\line.txt }
                if ($nextColorForce) {
                    $color = $nextColor
                } else {
                    $color = $null    
                }

                $nextColor = "Fred"
                $nextColorForce = $false

                # turn off quotes for edge cases where a sub-expression butts up to an end quote
                if ($inQuotes -and ($char -eq '"' -or $char -eq "'")) {
                    $inQuotes = $false
                    $quoteType = "Disable"
                }
            } elseif ($nextColor -ne "Fred" -and $nextColorLen -gt 0) {
                #if ($inMLC) { "Still in MLC - in next ($($cmdChars[$charNum]))" >> C:\temp\line.txt }
                # set the color
                if ($nextColorForce) {
                    $color = $nextColor
                    # the next color only needs to be set once, then it can be ignored
                    $nextColorForce = $false
                } else {
                    $color = $null    
                }

                # decrement length
                $nextColorLen = $nextColorLen - 1

                # turn off next color
                if ($nextColorLen -eq 0) {
                    $nextColor = "Fred"
                }
            } elseif ($inMLC) {
                #"Still in MLC" >> C:\temp\line.txt
                # get the entire line
                [string]$str = $cmdChars[$charNum]
                $tCount = $charNum + 1
                do {
                    $tChar = $cmdChars[$tCount]
                    $str = [string]::Concat($str, $tChar)
                    $tCount = $tCount + 1
                } until ($tChar -match "\n" -or $null -eq $tChar)

                # don't count NULL or the demo will hang
                $nxt = -1
                if ($null -eq $tChar) {
                    $nxt = $str.Length - 1
                } else {
                    $nxt = $str.Length - 2
                }

                # check if the end of the MLC is on this line, comment only through the #>
                if ($str.IndexOf('#>') -ne -1) {
                    $eol = $str.IndexOf('#>')
                    #"eol found at $eol. $($cmdChars[$eol])" >> C:\temp\line.txt
                    $color = $cmtColor
                    $nextColor = $cmtColor

                    # add 1 to grab the > after #
                    $nextColorLen = $eol + 1
                    # disable MLC so the big switch can highlight the rest of the line
                    $inMLC = $false
                } else {
                    $color = $cmtColor
                    if ($nxt -gt 0) {
                        $nextColor = $cmtColor
                        $nextColorLen = $nxt
                    }
                }

                #"nc: $nextColor; len: $nextColorLen" >> C:\temp\line.txt
            } else {
                switch -Regex ($char) {
                    $rgxVerbsFL {
                        # get the line
                        [string]$str = $_
                        $tCount = $charNum + 1
                        do {
                            $tChar = $cmdChars[$tCount]
                            $str = [string]::Concat($str, $tChar)
                            $tCount = $tCount + 1
                        } until ($null -eq $tChar -or $tChar -match "\n")

                        # don't count NULL or new line (\n) or the demo will hang
                        $str = $str.TrimEnd("\n").TrimEnd($null)
                        $nxt = $str.Length

                        if ((-NOT $inQuotes -and -NOT $inVar) -or $inSubExp ) {
                            # search for a cmdlet match
                            if ($str -match $rgxVerbs) {
                                # an cmdlet was found    
                                $color = $cmdColor
                                $nextColor = $cmdColor
                                $nextColorLen = $Matches.cl.Length - 1
                            # search for a statement match
                            } elseif ($str -match $rgxStatement) {
                                # a statement was found    
                                $color = $loopColor
                                $nextColor = $loopColor
                                $nextColorLen = $Matches.st.Length - 1
                            # loop control found
                            } elseif ($str -match $rgxLoopCtrl) { 
                                #Write-Host "`nloop control`n"
                                # a loop control statement was found    
                                $color = $lpCtlColor
                                $nextColor = $lpCtlColor
                                $nextColorLen = $Matches.lc.Length - 1
                            } elseif ( $str -match $rgxFunction )  {
                                # function or class found
                                $color = $varColor
                                $nextColor = $varColor
                                $nextColorLen = $Matches.st.Length - 1
                            } else {
                                # small optimization - use the next option to highlight the entire word
                                if ($str -match $rgxFndWord) {
                                    $color = $dfltColor
                                    $nextColor = $dfltColor
                                    $nextColorLen = $Matches.word.Length - 1
                                }
                            }
                        } elseif ($inQuotes) {
                            # small optimization - use the nextColor option to highlight the entire word
                            if ($str -match $rgxFndWord) {
                                $color = $quoteColor
                                $nextColor = $quoteColor
                                $nextColorLen = $Matches.word.Length - 1
                            } else {
                                $color = $quoteColor
                            }
                        } elseif ($inDT) {
                            # small optimization - use the nextColor option to highlight the entire word
                            if ($str -match $rgxFndDTWord) {
                                $color = $quoteColor
                                $nextColor = $quoteColor
                                $nextColorLen = $Matches.word.Length - 1
                            } else {
                                $color = $quoteColor
                            }
                        }
                    }

                    "\$" { 
                        <# conditions to highlight the variable
                            - Not in quotes
                            - In quotes and in a sub-expression
                            - In quotes and those quotes are double quotes ("")
                        
                        #>
                        if (-NOT $inQuotes -or 
                            ($inQuotes -and $inSubExp) -or 
                            ($inQuotes -and $quoteType -eq "Double")) {
                            # look ahead for a whitespace (\s) or new line (\n) or = . ( ) "
                            [string]$str = $_
                            $tCount = $charNum + 1
                            do {
                                $tChar = $cmdChars[$tCount]
                                $str = [string]::Concat($str, $tChar)
                                $tCount = $tCount + 1
                            } until ($tChar -match "\s" -or $tChar -match "\n" `
                                        -or $tChar -eq '=' -or $tChar -eq '.' `
                                        -or $tChar -eq ')' -or $tChar -eq '"' `
                                        -or $tChar -eq '(' -or $null -eq $tChar)
                            
                            # don't count NULL or the demo will hang
                            $nxt = -1
                            if ($null -eq $tChar) {
                                $nxt = $str.Length - 1
                            } else {
                                $nxt = $str.Length - 2
                            }

                            # do colors
                            $color = $varColor
                            if ($nxt -gt 0) {
                                $nextColor = $varColor
                                $nextColorLen = $nxt
                            # enable in sub-expression
                            } elseif ($cmdChars[$charNum + 1] -eq '(') {
                                $inSubExp = $true
                                $color = $dfltColor
                            } elseif ($inQuotes) {
                                $color = $quoteColor
                            }
                        # check for sub-expressions using a look ahead
                        } elseif ( $inQuotes -and $cmdChars[($charNum + 1)] -eq '(' ) {
                            $inSubExp = $true
                            $color = $dfltColor
                        } 
                        break
                    }

                    '-' {
                        if ( (-NOT $inQuotes -and -NOT $inVar -and -NOT $inSubExp) -or `
                                ($inQuotes -and $inSubExp -and $quoteType -eq "Double")) {
                            # look ahead for a whitespace (\s) or new line (\n)
                            [string]$str = $_
                            $tCount = $charNum + 1
                            do {
                                $tChar = $cmdChars[$tCount]
                                $str = [string]::Concat($str, $tChar)
                                $tCount = $tCount + 1
                            } until ($tChar -match "\s" -or $tChar -match "\n" -or $null -eq $tChar)
                            
                            # don't count NULL or the demo will hang
                            $nxt = -1
                            if ($null -eq $tChar) {
                                $nxt = $str.Length - 1
                            } else {
                                $nxt = $str.Length - 2
                            }

                            # setup color
                            $color = $paramColor
                            if ($nxt -gt 0) {
                                $nextColor = $paramColor
                                $nextColorLen = $nxt
                            }
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    '=' {
                        if ( -NOT $inQuotes -or $inSubExp ) {
                            $color = $eqColor
                        } elseif ( $inQuotes ) {
                            $color = $quoteColor
                        }
                        break
                    }

                    ';' {
                        if ( -NOT $inQuotes ) {
                            $color = $dfltColor
                        }
                        break
                    }

                    "\." {
                        if ( -NOT $inQuotes ) {
                            $color = $dfltColor
                            # cancel in variable
                            if ( $inVar ) { $inVar = $false }
                        } elseif ($inSubExp -and $inVar) {
                            $inVar = $false
                        } elseif ($inQuotes -and -NOT $inSubExp) {
                            $color = $quoteColor
                        }
                        break
                    }

                    "\{" {
                        if ( -NOT $inQuotes ) {
                            $color = $dfltColor
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    "\}" {
                        if ( -NOT $inQuotes ) {
                            $color = $dfltColor
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    "\(" {
                        if ( -NOT $inQuotes -or ($inQuotes -and $inSubExp) ) {
                            $color = $dfltColor
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    "\)" {
                        if ( -NOT $inQuotes ) {
                            $color = $dfltColor
                        } elseif ( $inSubExp ) {
                            $inSubExp = $false
                            if ($inQuotes) {
                                $nextColor = $quoteColor
                            } else {
                                $nextColor = $dtColor   
                            }
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    '"' {
                        # in quotes already?
                        if ($inQuotes -and $quoteType -eq "Double") {
                            # at the end of double-quotes, so turn off quotes mode
                            $inQuotes = $false
                            $quoteType = "Disable"
                        } else {
                            $inQuotes = $true
                            $quoteType = "Double"
                        }
                        $color = $quoteColor
                        break
                    }

                    "'" {
                        # in quotes already?
                        if ($inQuotes -and $quoteType -eq "Single") {
                            # at the end of double-quotes, so turn off quotes mode
                            $inQuotes = $false
                            $quoteType = "Disable"
                        } else {
                            $inQuotes = $true
                            $quoteType = "Single"
                        }
                        $color = $quoteColor
                        break
                    }

                    ' ' {
                        # turn of variable mode
                        if ($inVar) {
                            $inVar = $false
                            $color = $dfltColor
                        }

                        # turn off parameter coloring
                        if ($inParam) {
                            $inParam = $false
                            $color = $dfltColor
                        }

                        if (-NOT $inQuotes) {
                            $color = $dfltColor
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    '#' {
                        # everything after the comment is cmtColor, unless inside quotes
                        if ( -NOT $inQuotes ) {
                            # look ahead for a new line (\n) or $null
                            [string]$str = $_
                            $tCount = $charNum + 1
                            do {
                                $tChar = $cmdChars[$tCount]
                                $str = [string]::Concat($str, $tChar)
                                $tCount = $tCount + 1
                            } until ($tChar -match "\n" -or $null -eq $tChar)
                            
                            # don't count NULL or the demo will hang
                            $nxt = -1
                            if ($null -eq $tChar) {
                                $nxt = $str.Length - 1
                            } else {
                               $nxt = $str.Length - 2
                            }
                            
                            $color = $cmtColor
                            if ($nxt -gt 0) {
                                $nextColor = $cmtColor
                                $nextColorLen = $nxt
                            # enable in sub-expression
                            }
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                    }

                    "\[" {
                        if (-NOT $inQuotes -or ($inQuotes -and $inSubExp)) {
                            # get the data type text
                            [string]$str = $_
                            $tCount = $charNum + 1
                            do {
                                $tChar = $cmdChars[$tCount]
                                $str = [string]::Concat($str, $tChar)
                                $tCount = $tCount + 1
                            } until ($null -eq $tChar -or $tChar -match "\n" -or $tChar -match "\[" -or $tChar -match "\]")

                            # set the color
                            $color = $dtColor
                            # mark in data type
                            $inDT = $true
                            # increase the level
                            $dtLevel++

                            # small optimization - use the nextColor option to highlight the entire word
                            if ($str -match $rgxFndDTWord) {
                                $nextColor = $quoteColor
                                $nextColorLen = $Matches.word.Length - 1
                                $nextColorForce = $true
                            }

                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    "\]" {
                        if (-NOT $inQuotes -or ($inQuotes -and $inSubExp)) {
                            # set the color
                            $color = $dtColor
                            # decrease the level
                            $dtLevel--
                            # disable inDT when level hits 0
                            if ($dtLevel -le 0) {
                                $inDT = $false
                            }
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    <# not needed anymore...
                    "\n" {
                        # tracks whether the text is inside quotes
                        $inQuotes = $false
                        [DemoQuoteType]$quoteType = "Single"

                        # reset everything on a new line
                        # used to color the variable
                        $inVar = $false

                        # used to color a data type
                        $inDT = $false
                        $dtLevel = 0

                        # track sub-expressions
                        $inSubExp = $false

                        # used to color parameters
                        $inParam = $false

                        # next color, for situations where there is no good way to end a color scheme
                        # nextColor = "Fred" turns off nextColor
                        $nextColor = "Fred"

                        # how long to maintain the color
                        $nextColorLen = 0
                        break
                    }
                    #>

                    '<' {
                        # everything after the multi-line comment (MLC) is cmtColor, unless inside quotes
                        if ( -NOT $inQuotes -and $cmdChars[($charNum + 1)] -eq '#' ) {
                            # look ahead for a new line (\n) or $null
                            [string]$str = $_
                            $tCount = $charNum + 1
                            do {
                                $tChar = $cmdChars[$tCount]
                                $str = [string]::Concat($str, $tChar)
                                $tCount = $tCount + 1
                            } until ($tChar -match "\n" -or $null -eq $tChar)

                            # it's possible that a MLC is on a single line so account for that
                            if ($str.IndexOf('#>') -ne -1) {
                                # this is single line multi-line comment, highlight through the end of comment
                                $eoc = $str.IndexOf('#>') + 1
                                $nextColor = $cmtColor
                                $nextColorLen = $eoc
                            } else {
                                
                                # don't count NULL or the demo will hang
                                $nxt = -1
                                if ($null -eq $tChar) {
                                    $nxt = $str.Length - 1
                                } else {
                                    $nxt = $str.Length - 2
                                }
                                
                                $color = $cmtColor
                                if ($nxt -gt 0) {
                                    $nextColor = $cmtColor
                                    $nextColorLen = $nxt
                                }

                                # turn on inMLC
                                $inMLC = $true
                                #"start inMLC" >> C:\temp\line.txt
                                #"nc: $nextColor; len: $nextColorLen" >> C:\temp\line.txt
                            }
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        }
                        break
                    }

                    '>' {
                        # eMLC is disabled at this point, so look for the previous char to determine if this is the end of an MLC
                        if ($cmdChars[($charNum - 1)] -eq '#' -and -NOT $inQuotes) {
                            $color = $cmtColor
                            $inMLC = $false
                            "end inMLC" >> C:\temp\line.txt
                        } elseif ($inQuotes) {
                            $color = $quoteColor
                        } else {
                            $color = $dfltColor
                        }
                        break
                    }

                    default {
                        # get the word
                        [string]$str = $_
                        $tCount = $charNum + 1
                        do {
                            $tChar = $cmdChars[$tCount]
                            $str = [string]::Concat($str, $tChar)
                            $tCount = $tCount + 1
                        } until ($null -eq $tChar -or $tChar -match "\n" -or $tChar -match "\s")

                        $word = $str | Select-String -Pattern $rgxFndWord | ForEach-Object { $_.Matches.Groups[1].Value }

                        if ($inQuotes -and $quoteType -eq "Single") {
                            $color = $quoteColor
                        } elseif ($inQuotes -and -NOT $inSubExp -and -NOT $inVar) {
                            $color = $quoteColor
                        } elseif ($inVar -and $inQuotes) {
                            $color = $varColor
                        } elseif ($inVar) {
                            $color = $varColor
                        } elseif ($inDT) {
                            $color = $dtColor
                        } elseif ($inParam) {
                            $color = $paramColor
                        } else {
                            $color = $dfltColor
                        }

                        if ($word.Length -gt 1) {
                            $nextColor = $color
                            $nextColorLen = $word.Length - 1
                        }
                        
                        break
                    }
                }
            }

            # write the char in the correct color
            #[System.Console]::Write(("`e$color$char"))

            # record the colorized char
            if ($null -ne $color) {
                $glStr = [string]::Concat($glStr, "`e${color}$char")
            # record char but use last escape color
            } else {
                $glStr = [string]::Concat($glStr, "$char")
            }
            
            
            # increment charNum
            $charNum = $charNum + 1
        }
        
        #[System.Console]::Write(''.PadRight(($Global:Host.UI.RawUI.WindowSize.Width - $charNum - 2), ' '))
        #$glStr = $glStr.PadRight(($Global:Host.UI.RawUI.WindowSize.Width - 5), ' ')
        #[System.Console]::Write("`e[37m`n")

        # [0m resets all ANSI escape sequences
        $glStr = [string]::Concat($glStr, "`e[0m")
        return $glStr
    }
}

<###DEMO-BREAK###>

class DemoLine {
    [string]
    $Line

    [string]
    $HighlightedLine
    
    [DemoLineType]
    $CurrentLineType

    [int]
    $RawLineLength

    [bool]
    $EnableMLC

    # no [DemoLineColoring] assumes syntax highlighting
    DemoLine([string]$rl) {
        $this.Line            = $rl
        $this.CurrentLineType = "None"
        $this.RawLineLength   = $this.Line.Length
        $this.HighlightedLine = $null
        $this.EnableMLC       = $false
    }

    # no [DemoLineColoring] assumes syntax highlighting, supports multi-line comment (MLC)
    DemoLine([string]$rl, [bool]$eMLC) {
        $this.Line            = $rl
        $this.CurrentLineType = "None"
        $this.RawLineLength   = $this.Line.Length
        $this.HighlightedLine = $null
        Write-Verbose "[DemoLine] - MLC state: $eMLC"
        $this.EnableMLC       = $eMLC
    }

    # allows solid line coloring
    DemoLine([string]$rl, [DemoLineColoring]$lc) {
        $this.Line            = $rl
        $this.CurrentLineType = "None"
        $this.RawLineLength   = $this.Line.Length
        if ($lc -eq "Solid") {
            $this.HighlightedLine = $rl
        }
        $this.EnableMLC       = $false
    }

    # all write commands use whitespace padding to prevent text bleed
    WriteLine() {
        [System.Console]::WriteLine($this.GetPaddedLine())
    }

    Write() {
        [System.Console]::Write($this.GetPaddedLine())
    }

    # colors must be ASCII escape colors
    WriteSolid($color) {
        [System.Console]::Write("${color}$($this.GetPaddedRawLine())")
    }

    # colors must be ASCII escape colors
    WriteLineSolid($color) {
        [System.Console]::WriteLine("${color}$($this.GetPaddedRawLine())")
    }

    [string]
    GetLine() {
        return $this.HighlightedLine
    }

    [string]
    GetRawLine() {
        return $this.Line
    }

    [string]
    GetPaddedLine() {
        return "$($this.HighlightedLine)$($this.GetLinePadding())"
    }

    [string]
    GetPaddedLine([int]$ln, [string]$Color) {
        $rawLine = [string]::Concat("${color}$("{0:000}" -f $ln): ", $this.HighlightedLine)
        
        # calculate padding
        [int]$pad = $Global:Host.UI.RawUI.WindowSize.Width - $this.RawLineLength - 5
        if ($pad -lt 0) { $pad = 0 }

        return (([string]::Concat($rawLine, "$(" "*$pad)")))
    }

    [string]
    GetPaddedRawLine() {
        return "$($this.Line)$($this.GetLinePadding())"
    }

    [string]
    GetLinePadding() {
        [int]$pad = $Global:Host.UI.RawUI.WindowSize.Width - $this.RawLineLength

        if ($pad -lt 0) { $pad = 0 }

        return (" "*$pad)
    }

    # returns the raw line that has been padded, colored, and has a line number
    [string]
    GetPaddedRawLine([int]$ln, [string]$Color) {
        #$rawLine = $this.Line

        # add the line number and color to the string
        $rawLine = [string]::Concat("${color}$("{0:000}" -f $ln): ", $this.Line)
        
        # calculate padding
        [int]$pad = $Global:Host.UI.RawUI.WindowSize.Width - $this.RawLineLength - 5
        if ($pad -lt 0) { $pad = 0 }

        return (([string]::Concat($rawLine, "$(" "*$pad)")))
    }

    # returns the raw line that has been padded and colored, without line numbers
    [string]
    GetPaddedRawLine([string]$Color) {
        return ("${Color}$($this.GetPaddedRawLine())")
    }

    SetPrint(){
        $this.CurrentLineType = "Print"
    }

    [string]
    ToLongString() {
        return @"
    
Line            : $($this.Line)
HighlightedLine : $($this.HighlightedLine)
CurrentLineType : $($this.CurrentLineType)
RawLineLength   : $($this.RawLineLength)

"@
    }
    
}

<###DEMO-BREAK###>

class DemoSegment {
    # all the lines in the segemnt
    [List[DemoLine]]
    $Line

    # the number of lines in the segment
    [int]
    $Count

    ### For use by DemoCommand ###
    # the location in the first segment line
    #hidden 
    [int]
    $TopLineNum

    # the location in the last segment line
    #hidden 
    [int]
    $BotLineNum

    hidden
    $Highlighter

    DemoSegment($l) {
        Write-Verbose "[DemoSegment] - Init"
        if ($l -is [string]) {
            Write-Verbose "[DemoSegment] - String passed."
            # split the string into lines
            $lns = [List[string]]::new()
            Write-Verbose "[DemoSegment] - Adding lines."
            $l -split "\r?\n" | & {process{ $lns.Add($_) }}
        } else {
            #write-host "not a string"
            # the try-catch will catch an invalid array type
            Write-Verbose "[DemoSegment] - Collection passed."
            $lns = $l
        }

        #Write-Host "$($lns.GetType().Name) - count: $($lns.Count)"

        # initialize the Line property
        $this.Line = [List[DemoLine]]::new()

        # the only highlighter is PowerShell at this time
        $this.Highlighter = [DemoHighlightPowerShell]::new()

        # process the lines
        $this.ProcessLines($lns)
        
        # populate length
        $this.Count = $this.Line.Count
        Write-Verbose "[DemoSegment] - Lines in this segment: $($this.Count)"
    }

    [DemoLine]
    GetLine([int]$ln) {
        if ($this.IsValidLine()) {
            return ($this.Line[$ln])
        } else {
            Write-Warning "The line number is out-of-bounds. The valid range is 0 thru $($this.Count - 1), inclusive."
            return $null
        }
    }

    ProcessLines($lns) {
        try {
            # tracks whether EnableMLC (Multi-Line Comment) should be enabled on a line
            $eMLC = $false

            foreach ($ln in $lns) {
                #"[DemoSegment] - Adding line (MLC: $eMLC): $ln" >> C:\temp\line.txt
                
                # test whether to enable MLC tracking
                # the line with <# does not have MLC enabled, as the highlighter captures that line. But, if there is a command before the <# the line is ignored
                # the line with #>, and all lines in between, have MLC enabled

                # matches a MLC after a single line comment
                [regex]$rgxMLCStart = "(?!<)#.*<#"

                # matches <# inside of quotes
                [regex]$rgxMLCInQuotes = '(("|'').*<#.*("|''))'

                if ($ln.IndexOf('<#') -ne -1 -and $ln -notmatch $rgxMLCStart -and $ln -notmatch $rgxMLCInQuotes) {
                    #"[DemoSegment] - Start of MLC: $ln" >> C:\temp\line.txt
                    # create the line with MLC disabled
                    $dl = [DemoLine]::new($ln)
                    
                    # highlight the line
                    $dl.HighlightedLine = $this.Highlighter.HighlightLinePowerShell($ln)

                    # enable MLC
                    $eMLC = $true
                } elseif ( $eMLC -and $ln.IndexOf('#>') -ne -1) {
                    #"[DemoSegment] - End of MLC: $ln" >> C:\temp\line.txt
                    # create the line with MLC enabled
                    $dl = [DemoLine]::new($ln, $true)

                    # highlight the line with MLC enabled
                    $dl.HighlightedLine = $this.Highlighter.HighlightLinePowerShell($ln, $true)

                    # disable MLC
                    $eMLC = $false
                } elseif ($eMLC) {
                    #"[DemoSegment] - Line within MLC: $ln" >> C:\temp\line.txt
                    # create the line with MLC enabled
                    $dl = [DemoLine]::new($ln, $true)

                    # highlight the line with MLC enabled
                    $dl.HighlightedLine = $this.Highlighter.HighlightLinePowerShell($ln, $true)
                } else {
                    # create the line with MLC disabled
                    $dl = [DemoLine]::new($ln)

                    # highlight the line
                    $dl.HighlightedLine = $this.Highlighter.HighlightLinePowerShell($ln)
                }

                # add the completed [DemoLine] to the segment
                $this.Line.Add($dl)
            }
        } catch {
            throw "Failed to create the segment. Error: $_"
        }
    }

    [List[DemoLine]]
    GetAllLines() {
        return ($this.Line)
    }

    AddLine([List[DemoLine]]$ln) {
        $this.Line.AddRange($ln)
    }

    [bool]
    IsValidLine([int]$num) {
        return (($num -lt $this.Count -and $num -ge 0))
    }

    Update() {
        foreach ($ln in $this.Line) {
            $tmpLn = $this.Highlighter.HighlightLinePowerShell($ln.Line, $ln.EnableMLC)
            #Write-Host "new line: $tmpLn"
            if ( -NOT [string]::IsNullOrEmpty($tmpLn) -and -NOT [string]::IsNullOrWhiteSpace($tmpLn) -and $tmpLn -ne "DemoLine" ) {
                $ln.HighlightedLine = $tmpLn
            }
        }
    }

}

<###DEMO-BREAK###>

# runs and manages the demo commands
class Demo {
    #region
    [DemoType]
    $Type
    
    [string[]]
    $Command

    [string]
    $Comment

    [List[DemoSegment]]
    $Segment

    [System.IO.FileInfo]
    $DemoFile

    [int]
    $TotalLines

    [int]
    $NumSegments

    [bool]
    $EnableLineNumbers

    [string]
    $FadeIn1

    [string]
    $FadeIn2

    [string]
    $FadeIn3

    [string]
    $FadeOut1

    [string]
    $FadeOut2

    [string]
    $FadeOut3

    [string]
    $DefaultLineColor

    # Stores all the demo lines together
    hidden
    [List[DemoLine]]
    $AllLines

    hidden
    $Highlighter

    # only used by single command demos
    # line numbers are disbled by default
    Demo(
        [string]
        $Cmd,
    
        [string]
        $Cmt
    ) {
        Write-Verbose "[Demo] - Single command."
        $this.Type    = "Single"
        $this.Command = $Cmd
        $this.Comment = $Cmt
        $this.EnableLineNumbers = $false
        $this.DemoFile = $null

        # the only highlighter is PowerShell at this time
        $this.Highlighter = [DemoHighlightPowerShell]::new()

        # set default colors
        $this.FadeIn1  = "`e[38;2;50;50;50m"
        $this.FadeIn2  = "`e[38;2;75;75;75m"
        $this.FadeIn3  = "`e[38;2;100;100;100m" 
        $this.FadeOut1 = "`e[38;2;100;100;100m" 
        $this.FadeOut2 = "`e[38;2;75;75;75m"
        $this.FadeOut3 = "`e[38;2;50;50;50m"
        $this.DefaultLineColor = "`e[38;2;204;204;204m"

        Write-Verbose "[Demo] - Validate"
        $this.ValidateClass()

        # pre split the command into segments, which is the command split into lines
        Write-Verbose "[Demo] - Init List[DemoSegment]"
        $this.Segment = [List[DemoSegment]]::new()
        $this.ConvertCommandToSegment()
        $this.NumSegments = $this.Segment.Count

        # build the AllLines property
        $this.AllLines = [List[DemoLine]]::new()
        foreach ($seg in $this.Segment) { $this.AllLines.AddRange($seg.GetAllLines()) }
        $this.TotalLines = $this.AllLines.Count
    }

    # can be used by single or multi, but NOT file
    Demo(
        [DemoType]
        $t,

        [string[]]
        $Cmd,
    
        [string]
        $Cmt
    ) {
        $this.Type    = $t
        Write-Verbose "[Demo] - $($this.Type)"
        $this.Command = $Cmd
        $this.Comment = $Cmt
        $this.DemoFile = $null

        # the only highlighter is PowerShell at this time
        $this.Highlighter = [DemoHighlightPowerShell]::new()

        # set default colors
        $this.FadeIn1  = "`e[38;2;50;50;50m"
        $this.FadeIn2  = "`e[38;2;75;75;75m"
        $this.FadeIn3  = "`e[38;2;100;100;100m" 
        $this.FadeOut1 = "`e[38;2;100;100;100m" 
        $this.FadeOut2 = "`e[38;2;75;75;75m"
        $this.FadeOut3 = "`e[38;2;50;50;50m"
        $this.DefaultLineColor = "`e[38;2;204;204;204m"

        # enable line numbers for everything but single
        if ($t -eq "Single") {
            $this.EnableLineNumbers = $false
        } else {
            $this.EnableLineNumbers = $true
        }

        $this.ValidateClass()

        # pre split the command into segments, which is the command split into lines
        $this.Segment = [List[DemoSegment]]::new()
        $this.ConvertCommandToSegment()
        $this.NumSegments = $this.Segment.Count

        # build the AllLines property
        $this.AllLines = [List[DemoLine]]::new()
        foreach ($seg in $this.Segment) { $this.AllLines.AddRange($seg.GetAllLines()) }
        $this.TotalLines = $this.AllLines.Count
    }

    # used by ONLY file
    Demo(
        [System.IO.FileInfo]
        $file,
    
        [string]
        $Cmt
    ) {
        $this.Type    = "File"
        Write-Verbose "[Demo] - $($this.Type)"
        $this.Comment = $Cmt
        $this.DemoFile = $file

        # the only highlighter is PowerShell at this time
        $this.Highlighter = [DemoHighlightPowerShell]::new()

        # set default colors
        $this.FadeIn1  = "`e[38;2;50;50;50m"
        $this.FadeIn2  = "`e[38;2;75;75;75m"
        $this.FadeIn3  = "`e[38;2;100;100;100m" 
        $this.FadeOut1 = "`e[38;2;100;100;100m" 
        $this.FadeOut2 = "`e[38;2;75;75;75m"
        $this.FadeOut3 = "`e[38;2;50;50;50m"
        $this.DefaultLineColor = "`e[38;2;204;204;204m"

        # enable line numbers 
        $this.EnableLineNumbers = $true

        # pre split the command into segments, which is the command split into lines
        Write-Verbose "[Demo] - Converting the file to segments."
        $this.Segment = [List[DemoSegment]]::new()
        $this.ConvertFileToSegment()
        $this.NumSegments = $this.Segment.Count

        # build the AllLines property
        $this.AllLines = [List[DemoLine]]::new()
        foreach ($seg in $this.Segment) { $this.AllLines.AddRange($seg.GetAllLines()) }
        $this.TotalLines = $this.AllLines.Count
    }

    #endregion
    
    ConvertFileToSegment() {
        # The FILE type looks for a key line and splits the document at those lines.
        # The key line is (minus the space between < and #):
        #
        # <###DEMO-BREAK###>
        #
        # This must be the only non-whitespace characters on the line!

        # stores all the lines until a key line is reached
        $currCmd = [List[string]]::new()
        Write-Verbose "[Demo].ConvertFileToSegment - currCmd created."

        # track where segments are within the entire command
        $topLine = 0
        $botLine = 0

        # add a prompt for large files that may take a while to process
        [System.Console]::CursorVisible = $false
        [System.Console]::Write("Processing the file")
        $numDots = 1
        $dot = '.'
        $curPos = $global:Host.UI.RawUI.CursorPosition
        $sw = [System.Diagnostics.Stopwatch]::new()
        $sw.Start()

        switch -Regex -File "$($this.DemoFile.FullName)" {
            "^\s*<###DEMO-BREAK###>\s*$" {
                # key line has been found
                Write-Verbose "[Demo].ConvertFileToSegment - Key line reached."

                # add to command
                $this.Command += $currCmd

                # increment segments
                #$this.NumSegments = $this.NumSegments + 1

                Write-Verbose "[Demo].ConvertFileToSegment - Lines added to Command: $($currCmd.Count)"

                # add the segment
                Write-Verbose "[Demo].ConvertFileToSegment - Adding DemoSegment."
                $tmpSeg = [DemoSegment]::new($currCmd)
                $tmpSeg.TopLineNum = $topLine
                # adjust to zero-index
                $botLine = $topLine + $tmpSeg.Count - 1
                $tmpSeg.BotLineNum = $botLine

                $this.Segment.Add($tmpSeg)

                # update topline to be the next segments topLineNum
                $topLine = $botLine + 1
                
                # reset the lines and continue
                Write-Verbose "[Demo].ConvertFileToSegment - Reset currCmd."
                $currCmd.Clear()

                if ($sw.Elapsed.TotalSeconds -gt 1) {
                    if ($numDots -gt 3) {
                       $numDots = 1
                       $global:Host.UI.RawUI.CursorPosition = $curPos
                       [System.Console]::Write('   ')
                       $global:Host.UI.RawUI.CursorPosition = $curPos
                    }
              
                    [System.Console]::Write($dot)
                    $numDots++
                    $sw.Restart()
                }
            }

            default {
                Write-Debug "[Demo].ConvertFileToSegment - Added line: $PSItem"
                # record the line
                $currCmd.Add($PSItem)

                if ($sw.Elapsed.TotalSeconds -gt 1) {
                    $global:Host.UI.RawUI.CursorPosition = $curPos
                    $dots = ("."*$numDots).PadRight(3, " ")
                    [System.Console]::Write($dots)
                    $numDots++
                    if ($numDots -gt 3) {
                        $numDots = 0
                    }
                    $sw.Reset()
                }
            }
        }

        # save the bottom section of the file
        if ($currCmd.Count -gt 0) {
            Write-Verbose "[Demo].ConvertFileToSegment - End of file reached."

            # add to command
            $this.Command += $currCmd

            # increment segments
            #$this.NumSegments = $this.NumSegments + 1

            Write-Verbose "[Demo].ConvertFileToSegment - Lines added to Command: $($currCmd.Count)"

            # add the segment
            Write-Verbose "[Demo].ConvertFileToSegment - Adding DemoSegment."
            $tmpSeg = [DemoSegment]::new($currCmd)
            $tmpSeg.TopLineNum = $topLine
            # adjust to zero-index
            $botLine = $topLine + $tmpSeg.Count - 1
            $tmpSeg.BotLineNum = $botLine

            $this.Segment.Add($tmpSeg)
        }

        $this.ClearCurrentLine()
        [System.Console]::CursorVisible = $true

        # add up all the lines
        $this.TotalLines = $this.Segment | ForEach-Object Count | Measure-Object -Sum | ForEach-Object Sum

        Write-Verbose "[Demo].ConvertFileToSegment - Done"
    }

    ConvertCommandToSegment() {
        Write-Verbose "[Demo].ConvertCommandToSegment - Number of command segments: $($this.Command.Count)"
        # add segments
        if ($this.Type -eq "Single") {
            Write-Verbose "[Demo].ConvertCommandToSegment - Add single segment.`n$($this.Command)"
            #$this.Demo.AddSegment($this.Command)  
            $tmpSeg = [DemoSegment]::new($this.Command)
            $tmpSeg.TopLineNum = 0
            # adjust to zero-index
            $tmpSeg.BotLineNum = $tmpSeg.Count - 1

            Write-Verbose "[Demo].ConvertCommandToSegment - tmpSeg:`n$($tmpSeg | Format-List | Out-String)"
            $this.Segment.Add($tmpSeg)
            Write-Verbose "[Demo].ConvertCommandToSegment - Command added."
        } else {
            # track where segments are within the entire command
            $topLine = 0
            $botLine = 0

            foreach ($seg in $this.Command) {
                Write-Verbose "[Demo].ConvertCommandToSegment - Command: $seg"
                $tmpSeg = [DemoSegment]::new($seg)
                $tmpSeg.TopLineNum = $topLine
                # adjust to zero-index
                $botLine = $topLine + $tmpSeg.Count - 1
                $tmpSeg.BotLineNum = $botLine
                $this.Segment.Add($tmpSeg)

                # update topline to be the next segments topLineNum
                $topLine = $botLine + 1
            }
        }
    }

    ValidateClass() {
        ### VALIDATION ###

        # command must contain something
        switch ($this.Type) {
            "Single" {
                if ( [string]::IsNullOrEmpty($this.Command) -or [string]::IsNullOrWhiteSpace($this.Command) ) {
                    throw "The command is invalid. The command is null or empty."
                }
            }
        }

        # one segment commands should always be type single.
        # multi must have at least 2 segments
        if ($this.Type -eq "Multi" -and $this.Command.Count -eq 1) {
            Write-Verbose "[Demo].ValidateClass - Multi to single. Command count: $($this.Command.Count)"
            $this.Type = "Single"
        }
    }
    
    [string]
    PrintCommand() {
        # the original console foreground color
        $ogColor = [System.Console]::ForegroundColor

        # press is returned to Start-Demo to set the next action
        # the default action is run
        $press = 'r'

        switch -Regex ($this.Type) {
            'Single' {
                Write-Verbose "[Demo].PrintCommand() - Single command."
                # store all the lines
                $visLines = [List[string]]::new()
                
                # line count
                $i = 1

                # line number color
                $lnClr = "`e[38;2;80;80;80m"
                
                #`e[32;8;118;118;118m

                foreach ($line in $this.Segment.GetAllLines()) {
                    Write-Verbose "[Demo].PrintCommand() - raw line: $($line.GetLine())"
                    #$hl = $this.HighlightLine($line)
                    $hl = $line.GetLine()
                    
                    $ln = ""
                    if ($this.EnableLineNumbers) {
                        $ln = "$lnClr$("{0:00}" -f $i): $hl"
                        $i++
                    } else {
                        $ln = "$hl"
                    }
                    
                    $visLines.Add($ln)
                    
                }

                foreach ($ln in $visLines) {
                    [System.Console]::WriteLine($ln)
                }

                $this.SimpleWait()

                $press = 'r'
            }

            '(File|Multi)' {
                Write-Verbose "[Demo].PrintCommand() - Multi-segement command."

                # the current segment
                $currSegment = 0

                # set initial line postions
                $oldTopLine = 0
                $topLine = $this.Segment[$currSegment].TopLineNum

                # the lines that will visible
                $visLines = [System.Collections.Generic.List[string]]::new()
                $visHght = $this.Segment[$currSegment].Count
                $oldvisHght = $this.Segment[$currSegment].Count

                # line number color
                $lnClr = $this.FadeIn3

                # get the default console color
                $ogColor = $global:Host.UI.RawUI.ForegroundColor

                # set the default color to grey
                $fogc = $this.DefaultLineColor

                # get the cursor position
                $startCursorPos = $global:Host.UI.RawUI.CursorPosition
                
                # expand the buffer width
                $ogBuffSize = $global:Host.UI.RawUI.BufferSize
                $newBuffSize = $ogBuffSize
                $newBuffSize.Width = $newBuffSize.Width + 100
                $global:Host.UI.RawUI.BufferSize = $newBuffSize

                # turn off the cursor 
                [System.Console]::CursorVisible = $false

                # original encoding
                $ogEncoding = [System.Console]::OutputEncoding

                # force UTF-8 encoding
                [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

                # declaring this, changed after writes
                $script:resetPosition = [System.Management.Automation.Host.Coordinates]::new(0, 1)

                # loop time
                $done = $false

                $press = 'n'
                do {
                    # initial console size
                    $hMod = 2
                    $conHeight = $Global:Host.UI.RawUI.WindowSize.Height - $hMod

                    # Segments that are longer than the console height are handled differently than shorter
                    # I'm sure there's some smart way to merge the two, but I don't have the time to figure it out at the moment.
                    <#
                           ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ 
                        0  │ # comment line                                                                                                                      │ 
                        1  │ <blank or ...>                                                                                                                      │ 
                        2  │ 000: First line                                                                                                                     │ 
                        1  │                                                                                                                                     │ 
                        .  │                                                                                                                                     │ 
                        .  │                                                                                                                                     │ 
                        .  │                                                                                                                                     │ 
                        .   ...                                                                                                                                       
                       n-3 │ 999: Last line                                                                                                                      │ 
                       n-2 │ <blank or ...>                                                                                                                      │ 
                       n-1 │                                                                                                                                     │ 
                        n  │                                                                                                                                     │ 
                           └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘ 
                            
                        $Global:Host.UI.RawUI.WindowSize.Height returns the non-zero indexed height of the console. The line numbers start at 0, based on the CursorPosition Y value.

                        Based on the diagram above, 5 lines are used by whitespace and/or ellipses. Minus one more to adjust the console height for zero-indexing.

                        Which leaves console height minus 6 (hMod) available for demo lines.

                        Console width is adjusted by 1 to compensate for zero-indexing.
                    #>
                    if ($this.Segment[$currSegment].Count -gt $conHeight) {
                        # initial console size
                        $hMod = 6
                        $conHeight = $Global:Host.UI.RawUI.WindowSize.Height - $hMod
                        $conWidth = $Global:Host.UI.RawUI.WindowSize.Width - 1

                        ## set limits
                        # subract 3 from the minLineNum to capture the last 3 lines of the previous segment
                        if ($currSegment -ne 0) {
                            [int]$minLineNum = $this.Segment[$currSegment].TopLineNum - 3

                            # set the fadeIn line type
                            0..2 | ForEach-Object {
                                $ln = $minLineNum + $_
                                switch ($_) {
                                    0 { $this.AllLines[$ln].CurrentLineType = "FadeIn1"; break }
                                    1 { $this.AllLines[$ln].CurrentLineType = "FadeIn2"; break }
                                    2 { $this.AllLines[$ln].CurrentLineType = "FadeIn3"; break }
                                }
                            }
                        } else {
                            [int]$minLineNum = $this.Segment[$currSegment].TopLineNum
                        }
                        
                        # make sure the min line is never negative
                        if ($minLineNum -lt 0) { $minLineNum = 0 }

                        # add 1 to adjust for zero indexing, then add 3 if not the last segment to capture the footer (first 3 lines of the next segment)
                        if ($currSegment -lt ($this.NumSegments - 1)) {
                            [int]$maxLineNum = $this.Segment[$currSegment].BotLineNum + 3

                            # set the fadeOut line type
                            ($this.Segment[$currSegment].BotLineNum + 1)..($this.Segment[$currSegment].BotLineNum + 3) | ForEach-Object {
                                # switch control
                                $fon = $maxLineNum - $_
                                # preserves the pipeline num because the switch overwrites $_/$PSItem
                                $ln = $_
                                switch ($fon) {
                                    0 { $this.AllLines[$ln].CurrentLineType = "FadeOut3"; break }
                                    1 { $this.AllLines[$ln].CurrentLineType = "FadeOut2"; break }
                                    2 { $this.AllLines[$ln].CurrentLineType = "FadeOut1"; break }
                                }
                            }
                        } else {
                            [int]$maxLineNum = $this.Segment[$currSegment].BotLineNum # + 1
                        }
                        
                        
                        # make sure the max line is never larger than the final line
                        if ($maxLineNum -ge $this.TotalLines) { $maxLineNum = $this.TotalLines - 1 }

                        # used to exit the subsegment scrolling
                        $segDone = $false
                        
                        # move to the start position
                        $global:Host.UI.RawUI.CursorPosition = $startCursorPos

                        # pointer to the first visible line 
                        $pointer = $minLineNum

                        # determines the bottom most visible line, adjusted for zero-index
                        $botPointer = $pointer + $conHeight

                        # used by scrolling
                        $stopPointer = $botPointer

                        # directionality of the scrolling
                        $direction = "down"

                        # turn off the cursor
                        [System.Console]::CursorVisible = $false

                        # the visible lines
                        $visSubLines = [List[string]]::new()
                        # TOO SLOW $visSubLines = [List[DemoLine]]::new()

                        :print do {
                            # clear any old visible lines
                            $visSubLines.Clear()

                            # get current console size
                            # for conHeight, subtract 1 for zero-index, 1 for space line, 1 for the title, and 1 for the footer; the rest of the space is for visible lines
                            $conHeight = $Global:Host.UI.RawUI.WindowSize.Height - $hMod
                            $conWidth = $Global:Host.UI.RawUI.WindowSize.Width

                            # modify the height when a header is needed
                            if ($pointer -gt $minLineNum) {
                                # decrement and add the header
                                #$conHeight--

                                # add the header
                                $line = "...$(" "*($conWidth-3))"
                                $visSubLines.Add($line)
                            } else {
                                $visSubLines.Add("$(" "*$conWidth)")
                            }

                            # 

                            # scroll in the first subsegment
                            for ([int]$i = $pointer; $i -le $botPointer; $i++) {
                                #"$i - $($this.InRange($minLineNum, $maxLineNum, $i))" >> C:\temp\line.txt
                                if ( $this.InRange($minLineNum, $maxLineNum, $i) ) {
                                    $color = ''
                                    switch ($this.AllLines[$i].CurrentLineType) {
                                        "FadeIn1"  { $color = $this.FadeIn1 }
                                        "FadeIn2"  { $color = $this.FadeIn2 }
                                        "FadeIn3"  { $color = $this.FadeIn3 }
                                        "FadeOut1" { $color = $this.FadeOut1 }
                                        "FadeOut2" { $color = $this.FadeOut2 }
                                        "FadeOut3" { $color = $this.FadeOut3 }
                                        default    { $color = $null }
                                    }

                                    # highlighted line with numbers
                                    if ($null -eq $color -and $this.EnableLineNumbers) {
                                        $visSubLines.Add( $this.AllLines[$i].GetPaddedLine($i, $fogc) )
                                    # highlighted line without numbers
                                    } elseif ($null -eq $color -and -NOT $this.EnableLineNumbers) {
                                        $visSubLines.Add( $this.AllLines[$i].GetPaddedLine() )
                                    # solid colored line with numbers
                                    } elseif ($color -and $this.EnableLineNumbers) {
                                        $visSubLines.Add( $this.AllLines[$i].GetPaddedRawLine($i, $color) )
                                    # solid colored line without numbers
                                    } else {
                                        $visSubLines.Add( $this.AllLines[$i].GetPaddedRawLine($color) )
                                    }
                                }
                            }

                            # don't show elipsis (...) when at the end of the segment
                            if ($botPointer -eq $maxLineNum) {
                                $visSubLines.Add("$(" "*$conWidth)")
                            } else {
                                $visSubLines.Add("...$(" "*($conWidth-3))")
                            }

                            $botLine = "$($this.FadeIn2)[$("{0:000}" -f $pointer)-$("{0:000}" -f $botPointer)\$("{0:000}" -f $maxLineNum)] " 
                            
                            # at the last segment of the command/file
                            if ($currSegment -ge ($this.NumSegments - 1)) {
                                if ($botPointer -eq $maxLineNum) {
                                    $botLine = [string]::Concat($botLine, "[R]un ↑|w [lnUp] ←|a [pgUp] ↓|s [lnDown] →|d [pgDown] [b]ack s[k]ip [q]uit `e[0m")
                                } else {
                                    $botLine = [string]::Concat($botLine, "[r]un ↑|w [lnUp] ←|a [pgUp] ↓|s [lnDown] →|d [PgDOWN] [b]ack s[k]ip [q]uit `e[0m")
                                }
                                
                            # not at the end of the first segment
                            } elseif ($currSegment -eq 0 -and $botPointer -lt $stopPointer) {
                                $botLine = [string]::Concat($botLine, "[n]ext ↑|w [lnUp] ←|a [pgUp] ↓|s [lnDown] →|D [PgDOWN] s[k]ip [q]uit `e[0m")
                            # at the end of a segment, but not the last segment
                            } elseif ($botPointer -ge $maxLineNum -and $currSegment -lt ($this.NumSegments - 1)) {
                                $botLine = [string]::Concat($botLine, "[N]ext ↑|w [lnUp] ←|a [pgUp] ↓|s [lnDown] →|d [pgDown] s[k]ip [q]uit `e[0m")
                            # everything else
                            } else {
                                $botLine = [string]::Concat($botLine, "[n]ext ↑|w [lnUp] ←|a [pgUp] ↓|s [lnDown] →|D [PgDOWN] [b]ack s[k]ip [q]uit `e[0m")
                            }
                            
                            # add padding
                            $pad = $conWidth - 82
                            $botLine = [string]::Concat($botLine, " "*$pad)
                            $visSubLines.Add($botLine)

                            # print the text
                            $global:Host.UI.RawUI.CursorPosition = $startCursorPos
                            foreach ($l in $visSubLines) { [System.Console]::WriteLine($l) }

                            # record the current position for the end
                            $script:resetPosition = $Global:Host.UI.RawUI.CursorPosition
                            $script:resetPosition.Y = $script:resetPosition.Y + 1

                            if ( ($botPointer -ge $stopPointer -and $direction -eq "down") -or
                                ($botPointer -le $stopPointer -and $direction -eq "up")) {
                                
                                :input do {
                                    $repeat = $false
                                    $key = [System.Console]::ReadKey($true)

                                    if ($key.Key -eq "DownArrow" -or $key.Key -eq "s") {
                                        # scroll down one line
                                        $pointer++
                                        $botPointer++
                                        $stopPointer++
                                        $direction = "down"
                                    } elseif ($key.Key -eq "UpArrow" -or $key.Key -eq "w") {
                                        # scroll up one line
                                        $pointer--
                                        $botPointer--
                                        $stopPointer--
                                        $direction = "up"
                                    } elseif ($key.Key -eq "LeftArrow" -or $key.Key -eq "a") {
                                        # page up
                                        $pointer--
                                        $botPointer--
                                        $stopPointer = $botPointer - $conHeight
                                        $direction = "up"
                                    } elseif ($key.Key -eq "RightArrow" -or $key.Key -eq "d" -or
                                                ($key.Key -eq "Enter" -and $botPointer -lt $maxLineNum)) {
                                        # page down
                                        $pointer++
                                        $botPointer++
                                        $stopPointer = $botPointer + $conHeight
                                        $direction = "down"
                                    } elseif ($key.Key -eq "q") {
                                        $segDone = $true
                                        $done = $true
                                        $press = "q"
                                    } elseif ($key.Key -eq "r" -or
                                                ($key.Key -eq "Enter" -and $currSegment -ge ($this.NumSegments - 1))) {
                                        $segDone = $true
                                        $done = $true
                                        $press = "r"
                                    } elseif ($key.Key -eq "k") {
                                        $segDone = $true
                                        $done = $true
                                        $press = "s"
                                    # if the code gets all the way down here the Enter will go to the next segment
                                    } elseif ($key.Key -eq "n" -or $key.Key -eq "Enter") {
                                        $segDone = $true
                                        $press = "n"
                                        # increment segemt
                                        $currSegment++

                                        if ($currSegment -ge $this.NumSegments) {
                                            $currSegment = $this.NumSegments - 1
                                        }

                                        # update top and bottom line
                                        $oldTopLine = $maxLineNum - $conHeight
                                        $topLine = $this.Segment[$currSegment].TopLineNum

                                        # update visibile heights
                                        $oldvisHght = $conHeight - 6
                                        $visHght = $this.Segment[$currSegment].Count
                                    } elseif ($key.Key -eq "b") {
                                        $segDone = $true
                                        $press = "b"

                                        # decrement segemt
                                        $currSegment--

                                        if ($currSegment -lt 0) {
                                            $currSegment = 0
                                        }

                                        if ($currSegment -eq 0) {
                                            # update top and bottom line
                                            $oldTopLine = $minLineNum + $conHeight
                                            $topLine = 0
                                        } else {
                                            # update top and bottom line
                                            $oldTopLine = $botPointer
                                            $topLine = $this.Segment[$currSegment].TopLineNum
                                        }

                                        # update visibile heights
                                        $oldvisHght = $conHeight - $minLineNum
                                        $visHght = $this.Segment[$currSegment].Count
                                    } else {
                                        $repeat = $true
                                    }
                                } while ($repeat)
                            } else {
                                if ($direction -eq "down") {
                                    $pointer++
                                    $botPointer++

                                } else {
                                    $pointer--
                                    $botPointer--
                                }
                            }

                            if (-NOT $segDone) {
                                # prevent the last line of print from being past the segment's last line and bottom of console
                                if ($direction -eq "Down") {
                                    if ($botPointer -gt $maxLineNum) {
                                        $botPointer = $maxLineNum
                                        $pointer = $botPointer - $conHeight
                                    }

                                    if ($stopPointer -gt $maxLineNum) {
                                        $stopPointer = $maxLineNum
                                    }
                                # make sure the pointer never goes below 0 when going up
                                } else {
                                    if ($pointer -lt $minLineNum) {
                                        # pointer to the first visible line 
                                        $pointer = $minLineNum

                                        # determines the bottom most visible line
                                        $botPointer = $conHeight + $pointer

                                        # used by scrolling
                                        $stopPointer = $botPointer
                                    }

                                    if ($stopPointer -lt $conHeight) {
                                        $stopPointer = $conHeight
                                    }
                                }
                            } else {
                                # clear down through the bottom line
                                # the current console height 
                                $conHeight = $global:Host.UI.RawUI.WindowSize.Height

                                #$blankLine = ''.PadRight($conWidth, " ")
                                # create a blank line based on the current window width
                                # ASCII escape sequence to clear the line
                                $blankLine = "`e[2K"

                                for ($b = ($script:resetPosition.Y - 1); $b -lt $conHeight; $b++) { $visLines.Add($blankLine) }

                                # move to the bottom position
                                $global:Host.UI.RawUI.CursorPosition = $script:resetPosition
                            }

                        } until ($segDone)

                        $this.ResetLineType()
                    } else {
                        #region SHORT SEGMENT
                        ## Generate and write the console page
                        #region
                        # move to the start position
                        $global:Host.UI.RawUI.CursorPosition = $startCursorPos

                        # the current console width
                        $conWidth = $global:Host.UI.RawUI.WindowSize.Width
                        #$conWidth = $newBuffSize.Width

                        # the current console height minus 1 for the title and 1 for zero indexing and 1 for a blank space
                        $conHeight = $global:Host.UI.RawUI.WindowSize.Height - 2

                        # create a blank line based on the current window width
                        $blankLine = ''.PadRight($conWidth, " ")
                        
                        # build the visible lines
                        $fadeInCount = 0
                        $fadeOutColor = -1
                        
                        # some calculations for scrolling
                        if ($oldTopLine -le 2) {
                            $srtI = 0
                        } else {
                            $srtI = ($oldTopLine - 3)
                        }

                        $endI = ($oldTopLine + $oldVisHght + 2)
                        #"[Demo].PrintCommand - srtI: $srtI; endI: $endI" >> t:\temp\line.txt

                        for ($i = $srtI; $i -le $endI; $i++) {
                            #"[Demo].PrintCommand - i: $i" >> t:\temp\line.txt
                            #"$currSegment -lt ($($this.NumSegments) - 1) -and $i -gt $($this.Segment[$currSegment].BotLineNum) = $($currSegment -lt ($this.NumSegments - 1) -and $i -gt $this.Segment[$currSegment].BotLineNum)"  >> t:\temp\line.txt
                            if ($this.InRange($i)) {
                                #$line = ''
                                #$rawLnLen = $this.AllLines[$i].RawLineLength
                                if ($currSegment -gt 0 -and $fadeInCount -lt 3) {
                                    #"fadeInCount: $fadeInCount"  >> t:\temp\line.txt
                                    # fade in the top
                                    #$line = "$($fade[$fadeInCount])$("{0:000}" -f $i): $($this.AllLines[$i].GetRawLine())"
                                    $color = ''
                                    switch ($fadeInCount) {
                                        0 { $color = $this.FadeIn1; break }
                                        1 { $color = $this.FadeIn2; break }
                                        2 { $color = $this.FadeIn3; break }
                                    }
                                    
                                    if ($this.EnableLineNumbers) {
                                        $line = $this.AllLines[$i].GetPaddedRawLine($i, $color)
                                    } else {
                                        $line = $this.AllLines[$i].GetPaddedRawLine($color)
                                    }
                                    
                                    $fadeInCount++
                                } elseif ( $currSegment -lt ($this.NumSegments - 1) -and 
                                            $i -gt $this.Segment[$currSegment].BotLineNum) {
                                    
                                    #"fadeInCount: $fadeInCount"  >> t:\temp\line.txt
                                    #$line = "$($fade[$fadeOutColor])$("{0:000}" -f $i): $($this.AllLines[$i].GetRawLine())"
                                    $color = ''
                                    switch ($fadeOutColor) {
                                        -1 { $color = $this.FadeOut1; break }
                                        -2 { $color = $this.FadeOut2; break }
                                        -3 { $color = $this.FadeOut3; break }
                                    }
                                    
                                    if ($this.EnableLineNumbers) {
                                        $line = $this.AllLines[$i].GetPaddedRawLine($i, $color)
                                    } else {
                                        $line = $this.AllLines[$i].GetPaddedRawLine($color)
                                    }

                                    #"line: $line"  >> t:\temp\line.txt
                                    $fadeOutColor--
                                } else {
                                    #$hl = $this.HighlightLine( $this.Demo.Line[$i] )
                                    #$hl = $this.AllLines[$i].GetLine()
                                    # create the line with padding to overwrite longer lines occupying the same space
                                    #$line = "${lnClr}$("{0:000}" -f $i): $hl"
                                    if ($this.EnableLineNumbers) {
                                        $line = $this.AllLines[$i].GetPaddedLine($i, $fogc)
                                    } else {
                                        $line = $this.AllLines[$i].GetPaddedLine()
                                    }
                                    
                                }

                                # add the formatted line - PadRight doesn't work because of the ASCII escape characters, so do it manually
                                #$pad = $conWidth - $rawLnLen - 5 
                                #if ($pad -lt 0) { $pad = 0}
                                #$line = [string]::Concat($line, "$(" "*$pad)")
                                #"[Demo].PrintCommand - srtI: $srtI; endI: $endI; Line[$i]: $($this.AllLines[$i].ToLongString())" >> t:\temp\line.txt
                                $visLines.Add( $line )
                            }
                        }

                        # add a blank line
                        $visLines.Add($blankLine)

                        # add the prompt text
                        $endPfx = ""
                        $endSfx = "(s)kip, (q)uit"
                        if ($currSegment -eq 0) {
                            $endPfx = "${fogc}(N)ext, (r)un, "
                        } elseif ($currSegment -ge ($this.NumSegments - 1)) {
                            $endPfx = "${fogc}(R)un, (b)ack, "
                        } else {
                            $endPfx = "${fogc}(N)ext, (b)ack, (r)un, "
                        }
                        $endTxt = [string]::Concat($endPfx, $endSfx)

                        $visLines.Add($endTxt.PadRight($conWidth, " "))
                        #$visLines.Add("top: $topLine; oTop: $oldTopLine; bot: $($this.Segment[$currSegment].BotLineNum) vis: $visHght; oVis: $oldvisHght; visC: $($visLines.Count); stC: $($startCursorPos); srtI: $srtI; endI: $endI")
                        $visLines.Add($blankLine)

                        
                        # record the current position for the end
                        #$botCursorPosition = [System.Management.Automation.Host.Coordinates]::new(0, ($visLines.Count + 2))
                        $script:resetPosition = [System.Management.Automation.Host.Coordinates]::new(0, ($visLines.Count))

                        # add blank lines to the bottom of the console
                        for ($b = ($visLines.Count + 1); $b -lt $conHeight; $b++) { $visLines.Add($blankLine) }

                        #$null = [System.Console]::ReadKey($true)

                        # move to the start position
                        $global:Host.UI.RawUI.CursorPosition = $startCursorPos

                        # write the visibile lines
                        #$key = [Console]::ReadKey($true)
                        #$numLinesPrinted = $visLines.Count
                        #$visLines.Add("top: $topLine; oTop: $oldTopLine; vis: $visHght; oVis: $oldvisHght; visC: $($visLines.Count)")
                        foreach ($line in $visLines) { [System.Console]::WriteLine($line) }

                        # clear the visible lines
                        $visLines.Clear()

                        #"write done" >> T:\temp\line.txt

                        #engregion

                        if (($currSegment -eq 0 -and $press -eq 'n') -or 
                                (($oldTopLine -ge $topLine -and $visHght -eq $oldvisHght) -and $press -eq 'n') -or
                                (($oldTopLine -le $topLine -and $visHght -eq $oldvisHght) -and $press -eq 'b')
                            ) {
                            # wait for input
                            #"Segment path" >> T:\temp\line.txt
                            $resume = $false

                            :input do {
                                #"wait on input" >> T:\temp\line.txt
                                $key = [Console]::ReadKey($true)

                                if ($key.Key -eq "Enter") {
                                    #Write-Host "$currSegment -ge $($this.NumSegments - 1)"
                                    if ($currSegment -ge ($this.NumSegments - 1)) {
                                        $press = 'r'
                                    } else {
                                        $press = 'n'
                                    }
                                } else {
                                    $press = $key.Key
                                }

                                switch -Regex ($press) {
                                    "n" {
                                        # increment segemt
                                        $currSegment++

                                        if ($currSegment -ge $this.NumSegments) {
                                            $currSegment = $this.NumSegments - 1
                                            continue input
                                        }

                                        # update top and bottom line
                                        $oldTopLine = $topLine
                                        $topLine = $this.Segment[$currSegment].TopLineNum

                                        # update visibile heights
                                        $oldvisHght = $visHght
                                        $visHght = $this.Segment[$currSegment].Count

                                        # the visHght cannot be taller than the console's height
                                        # I don't have time to figure out scrolling a segment larger that
                                        # the console height so this breaks the demo scrolling at the moment.

                                        # exit input loop
                                        $resume = $true
                                    }

                                    "b" {
                                        # decrement segemt
                                        $currSegment--

                                        if ($currSegment -lt 0) {
                                            $currSegment = 0
                                            continue input
                                        }

                                        if ($currSegment -eq 0) {
                                            # update top and bottom line
                                            $oldTopLine = $topLine
                                            $topLine = 0
                                        } else {
                                            # update top and bottom line
                                            $oldTopLine = $topLine
                                            $topLine = $this.Segment[$currSegment].TopLineNum
                                        }

                                        # update visibile heights
                                        $oldvisHght = $visHght
                                        $visHght = $this.Segment[$currSegment].Count
                                        
                                        # exit input loop
                                        $resume = $true
                                    }

                                    'r|s|q' {
                                        # exit everything
                                        $resume = $true
                                        $done = $true
                                    }
                                }
                            } until ($resume)
                        } else {
                            if ($visHght -ne $oldvisHght) {
                                if ($visHght -gt $oldvisHght) {
                                    $oldvisHght++
                                } else {
                                    $oldvisHght--
                                }
                            }

                            # increment top
                            if ($press -eq 'b') {

                                $oldTopLine--

                                if ($oldTopLine -lt $topLine) {
                                    $oldTopLine = $topLine
                                }
                            } else {                           

                                $oldTopLine++

                                if ($oldTopLine -gt $topLine) {
                                    $oldTopLine = $topLine
                                }
                            }
                            
                            Start-Sleep -Milliseconds 30
                        }
                    }
                } until ($done)


                ## reset the console
                # the current console width
                #$conWidth = $global:Host.UI.RawUI.WindowSize.Width

                # the current console height 
                $conHeight = $global:Host.UI.RawUI.WindowSize.Height

                #$blankLine = ''.PadRight($conWidth, " ")
                # create a blank line based on the current window width
                # ASCII escape sequence to clear the line
                $blankLine = "`e[2K"

                for ($b = ($script:resetPosition.Y - 1); $b -lt $conHeight; $b++) { $visLines.Add($blankLine) }

                # move to the bottom position
                $global:Host.UI.RawUI.CursorPosition = $script:resetPosition

                # write the visibile lines
                foreach ($line in $visLines) { [System.Console]::Write($line) }


                # clear content below the demo text
                $global:Host.UI.RawUI.CursorPosition = $script:resetPosition

                [System.Console]::CursorVisible = $true
                [System.Console]::OutputEncoding = $ogEncoding

                #Write-Host "key: $($key.key)"

                # reset console to default color
                [System.Console]::ForegroundColor = $ogColor
            } #end Multi
        }

        return $press
    }

    Pause() {
        Write-Host "Press any key to continue..."
        $null = Read-Host
    }

    ClearBelow([System.Management.Automation.Host.Coordinates]$position) {
        # set cursor starting point
        $global:Host.UI.RawUI.CursorPosition = $position

        # clear the page
        $botPage = $Global:Host.UI.RawUI.WindowSize.Height - 2
        for ($l = $position.Y; $l -lt $botPage; $l++) {
            [System.Console]::WriteLine("".PadRight($global:Host.UI.RawUI.WindowSize.Width, ' '))
        }

        # set cursor starting point
        $global:Host.UI.RawUI.CursorPosition = $position
    }

    PrintLineSingleColor([string]$line, [string]$clr) {
        Write-Verbose "[Demo].PrintLineSingleColor - Recieved line: $line; color: $clr"
        # set the color based on whether it matches the list of console colors
        $conColors = [System.Enum]::GetValues([System.ConsoleColor])
        if ($clr -in $conColors) {
            Write-Verbose "[Demo].PrintLineSingleColor - Console color: $clr"
            Write-Host -ForegroundColor $clr -Object $line.PadRight($Global:Host.UI.RawUI.WindowSize.Width, ' ')
        # use console write if the color has an escape 
        } elseif ($clr -match "`e") {
            Write-Verbose "[Demo].PrintLineSingleColor - Escape color: $clr"
            [System.Console]::WriteLine("$clr$line".PadRight($Global:Host.UI.RawUI.WindowSize.Width, ' '))
        # use console write but add the escape if there is none
        } elseif ($clr -match "\[\d{2}.*m") {
            Write-Verbose "[Demo].PrintLineSingleColor - Escapable color: $clr"
            [System.Console]::WriteLine("`e$clr$line".PadRight($Global:Host.UI.RawUI.WindowSize.Width, ' '))
        } else {
            Write-Verbose "[Demo].PrintLineSingleColor - Unknown color option."
            Write-Host $line
        }
    }

    [void]
    PrintComment() {
        Write-Host -ForegroundColor Green "# $($this.Comment)"
    }

    SimpleWait() {
        # current cursor state
        $startCurVis = [Console]::CursorVisible

        # hide the console cursor
        [Console]::CursorVisible = $false
        
        # controls how many dots to print
        $count = 1
        $char = '.'

        # loop until a key is pressed
        while (-not [Console]::KeyAvailable) {
            # write a new dot
            #Write-Host $char -NoNewline
            [System.Console]::Write($char)

            # sleep to prevent the dots from looping too fast
            Start-Sleep -Milliseconds 500

            # increase the number of dots
            $count++

            # start over when 3 dots have printed
            if ($count -gt 3) {
                $count = 1
                $this.ClearCurrentLine()
            }
        }

        # read key or the next call will fail
        $null = [Console]::ReadKey()

        # return the console back to normal
        $this.ClearCurrentLine()
        [Console]::CursorVisible = $startCurVis
    }

    ClearCurrentLine() {
        # get the console length
        $conLen = $global:Host.UI.RawUI.WindowSize.Width

        # go to position 0 on the current line
        $currPosition = $global:Host.UI.RawUI.CursorPosition
        $currPosition.X = 0
        $global:Host.UI.RawUI.CursorPosition = $currPosition

        # write spaces
        Write-Host "$(''.PadRight($conLen, ' '))" -NoNewline

        # return to head of the line
        $global:Host.UI.RawUI.CursorPosition = $currPosition
    }

    [void]
    PrintComment([bool]$ClearHost) {
        if ($ClearHost) {
            Clear-Host
        }

        Write-Host -ForegroundColor Green "# $($this.Comment)"
    }

    [string]
    RunCommand() {
        switch ($this.Type) {
            "Single" {
                $cmd = $this.Command
                return (Invoke-Command -ScriptBlock ([scriptblock]::Create($cmd)) | Out-String)
            }

            "Multi" {
                # combine all the segments into a single command
                $cmd = $this.Command -join "`n"
                return (Invoke-Command -ScriptBlock ([scriptblock]::Create($cmd)) | Out-String)
            }

            "File" {
                # run the script in the same window
                $spLat = @{
                    FilePath         = "pwsh"
                    ArgumentList     =  "-NoProfile -NoProfileLoadTime -NoLogo -ep Bypass -wd `"$($this.DemoFile.DirectoryName)`" -File `".\$($this.DemoFile.Name)`""
                    WorkingDirectory = "$($this.DemoFile.DirectoryName)"
                    NoNewWindow      = $true
                    Wait             = $true
                }
                $results = Start-Process @spLat
                

                return $results
            }
        }

        Write-Warning "[Demo].RunCommand - An unsupported Demo type was used."
        return $null
    }

    [string]
    RunCommand([bool]$ClearHost) {
        if ($ClearHost) {
            Clear-Host
        }
        return ($this.RunCommand())
    }

    [bool]
    InRange([int]$num) {
        #"[Demo].InRange - 0: 0; tl: $($this.TotalLines) num: $num" >> t:\temp\line.txt
        return (($num -ge 0 -and $num -lt $this.TotalLines) ? $true : $false)
    }

    [bool]
    InRange([int]$min, [int]$max, [int]$num) {
        #"[Demo].InRange - min: $min; max: $max; num: $num; res: $($num -ge $min -and $num -le $max)" >> c:\temp\line.txt
        return (($num -ge $min -and $num -le $max) ? $true : $false)
    }

    UpdateColor([DemoHighlightColor]$ColorName, [string]$AsciiColor, [bool]$Update) {
        # updates the main highlight color and the colors of the segment highlighters
        $this.Highlighter.SyntaxColor.SetColor($ColorName, $AsciiColor)

        foreach ($seg in $this.Segment) {
            $seg.Highlighter.SyntaxColor.SetColor($ColorName, $AsciiColor)
        }

        if ($Update) {
            foreach ($ln in $this.AllLines) {
                # pass EnableMLC to the highlighter for multi-line comment support
                $tmpLn = $this.Highlighter.HighlightLinePowerShell($ln.Line, $ln.EnableMLC)

                #Write-Host "new line: $tmpLn"
                if ( -NOT [string]::IsNullOrEmpty($tmpLn) -and -NOT [string]::IsNullOrWhiteSpace($tmpLn) -and $tmpLn -ne "DemoLine" ) {
                    $ln.HighlightedLine = $tmpLn
                }
            }
        }
    }

    DisableLineNumbers() {
        $this.EnableLineNumbers = $false
    }

    EnableLineNumbers() {
        $this.EnableLineNumbers = $true
    }

    ResetLineType() {
        foreach ($ln in $this.AllLines) { $ln.CurrentLineType = "None" }
    }
}

<###DEMO-BREAK###>

# a simple function that automates creating the collection which contains all the demo commands
# the collection is not returned to ease management of the demo
function script:Initialize-Demo {
    [CmdletBinding()]
    param ()

    Write-Verbose "Initialize-Demo - Creating the libDemo object."
    $script:libDemo = [System.Collections.Generic.List[Demo]]::new()
}

# adds a command to the demo
# there is currently no remove because demos are meant to be prepared
# and well tested content
function script:Add-DemoCommand {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="cmd")]
        [string]
        $Command,

        [Parameter(ParameterSetName="segment")]
        [string[]]
        $Segment,

        [Parameter(ParameterSetName="file")]
        $File,

        [Parameter(Position = 1)]
        [string]
        $Comment,

        [Parameter()]
        [switch]
        $DisableLineNumbers
    )

    Write-Verbose "Add-DemoCommand - Start"
    $cmd = ''
    switch ($PSCmdlet.ParameterSetName) {
        "cmd" {
            Write-Verbose "Add-DemoCommand - Single command."
            try {
                $cmd = [Demo]::new($Command, $Comment)
                #$script:libDemo.Add($cmd)
            } catch {
                return (Write-Error "Failed to add the command. Error: $_" -EA Stop)
            }
        }

        "segment" {
            Write-Verbose "Add-DemoCommand - Multi-segment command."
            try {
                $cmd = [Demo]::new("Multi", $Segment, $Comment)
                #$script:libDemo.Add($cmd)
            } catch {
                return (Write-Error "Failed to add the command. Error: $_" -EA Stop)
            }
        }

        'file' {
            Write-Verbose "Add-DemoCommand - File command."
            try {
                # trust that the FileInfo object exists, but not a file with a string name
                # the string needs to be converted in any event...
                if ($file -is [string]) {
                     Write-Verbose "Add-DemoCommand - Convert string file path to FileInfo object."
                    try {
                        $fileObj = Get-Item "$file" -EA Stop
                         Write-Verbose "Add-DemoCommand - File conversion success."
                    } catch [System.Management.Automation.ItemNotFoundException] {
                        throw "The demo file was not found: $_"
                    } catch {
                        throw "Unable to validate the demo file: $_"
                    }
                    
                } elseif ($file -is [System.IO.FileInfo]) {
                     Write-Verbose "Add-DemoCommand - Duplicate FileInfo object."
                    $fileObj = $file
                } else {
                    throw "Unsupported demo file format. Valid formats: [string] or [System.IO.FileInfo] (Get-Item)"
                }

                Write-Verbose "Add-DemoCommand - Creating [Demo]."
                $cmd = [Demo]::new($fileObj, $Comment)
                Write-Verbose "Add-DemoCommand - cmd:`n$($cmd | Format-List | Out-String)"
            } catch {
                return (Write-Error "Failed to add the command. Error: $_" -EA Stop)
            }
        }
    }

    if ($cmd -is [Demo]) {
        Write-Verbose "Add-DemoCommand - Cmd added to demoCommands."
        # disable line numbers
        if ($DisableLineNumbers.IsPresent) { 
            Write-Verbose "Initialize-Demo - Disabling line numbers."
            $cmd.DisableLineNumbers()
        }

        # add the demo to libDemo
        $script:libDemo.Add($cmd)
    } else {
        throw "Failed to create the Demo."
    }

    Write-Verbose "Add-DemoCommand - Done"
}

<###DEMO-BREAK###>

function script:Set-DemoColor {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [DemoHighlightColor]
        $ColorName,

        [Parameter(Position=1)]
        [string]
        $AsciiColor,

        # Blocks reprocessing the highlighted lines. Used to reduce processing when changing multiple colors.
        [switch]
        $Update
    )

    try {
        # all the lines are pre-processed, so re-process the lines when the color is changed
        $script:libDemo.UpdateColor($ColorName, $AsciiColor, $Update.IsPresent)
    } catch {
        throw "Failed to set the demo color. Error: $_"
    }
}

function script:Get-DemoColor {
    [CmdletBinding()]
    param (
        [Parameter()]
        [DemoHighlightColor]
        $ColorName,

        [switch]
        $All
    )

    if ($All.IsPresent) {
        $script:libDemo.Segment[0].Highlighter.SyntaxColor.WritePrettyString()
    } else {
        $script:libDemo.Segment[0].Highlighter.SyntaxColor.GetColorVisible($ColorName)
    }
}

function script:Start-Demo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        [ValidateSet("FancyBounce", "Simple")]
        $WaitType = "FancyBounce"
    )

    # the original console foreground color
    #$ogColor = [System.Console]::ForegroundColor

    $count = 0
    $continue = $true
    :main while ($count -lt $script:libDemo.Count -and $continue) {
        #$key = [Console]::ReadKey($true)
        # print stuff
        $script:libDemo[$count].PrintComment($true)
        $command = $script:libDemo[$count].PrintCommand()

        # OPTIONS
        #
        # R = Run the demo
        # Q = Quit the demo
        # S = Skip this demo
        switch ($command) {
            'r' {
                # run the command
                # run the command
                Write-Host -ForegroundColor Yellow "`nResult:`n"
                [System.Console]::Write("`n")
                $script:libDemo[$count].RunCommand()
            }

            'q' {
                # quit the demo
                break main
            }

            's' {
                # skip this demo
                $count++
                continue main
            }

            default {
                # throw an error when an invalid option is returned
                throw "An invalid demo option was returned by DemoCommand. Option: $command; Valid options: R, Q, S"
            }
        }
        

        # wait during explanation
        [System.Console]::Write("`r`n")

        # tracks the start of the options line
        $startPosition = $Host.UI.RawUI.CursorPosition

        # wait on input
        :input do {
            # controls the option loop
            $loop = $false

            # print options and wait for prompt
            #$opt = Read-Host "(N)ext, (b)ack, (r)epeat, (c)lear and repeat, (q)uit"
            #Write-Host -ForegroundColor Yellow "(N)ext, " -NoNewline
            #Write-Host -ForegroundColor $ogColor "(b)ack, (r)epeat, (c)lear and repeat, (q)uit: " -NoNewline
            #$key = [Console]::ReadKey($true)
            

            # OPTIONS
            #
            # N = Next demo (default)
            # B = Previous demo
            # Q = Quit

            $op = 'n'
            switch ($WaitType) {
                "Simple" {
                    Start-SimpleWait
                    # simple only supports "next"
                }

                "FancyBounce" {
                    # ops are run, forward, back, quit
                    $op = Start-FancyBouncyWait
                }
            }
            
            # remove the options prompt
            $Host.UI.RawUI.CursorPosition = $startPosition
            Clear-CurrentLine
            [System.Console]::Write("`n")
            Write-Verbose "Start-Demo - op: $op; count: $count"

            # process the option
            switch ($op) {
                "N" { 
                    Write-Verbose "Start-Demo - Next demo"
                    $count++
                    if ($count -ge $script:libDemo.Count) {
                        Write-Verbose "Start-Demo - Last demo done, exiting."
                        break main
                    }
                    Write-Verbose "Start-Demo - New count: $count"
                }
                "B" { 
                    Write-Verbose "Start-Demo - Go to previous demo"
                    if ($count -ge 1) {
                        Write-Verbose "Start-Demo - dec count"
                        $count--
                    } 
                    Write-Verbose "Start-Demo - New count: $count"
                }
                "Q" { 
                    Write-Verbose "Start-Demo - Quit the demo"
                    break main
                }
                default {
                    Write-Verbose "Start-Demo - Get new input"
                    # invalid entry, loop
                    continue input
                }
            }
        } until (-NOT $loop -or -NOT $continue)
        #$key = [Console]::ReadKey($true)
    }
}

<###DEMO-BREAK###>
##### UTILITY #####

# deletes all the conent on the current line and replaces it with whitespace
function Clear-CurrentLine {
    # get the console length
    $conLen = $Host.UI.RawUI.WindowSize.Width

    # go to position 0 on the current line
    $currPosition = $Host.UI.RawUI.CursorPosition
    $currPosition.X = 0
    $Host.UI.RawUI.CursorPosition = $currPosition

    # write spaces
    Write-Host "$(''.PadRight($conLen, ' '))" -NoNewline

    # return to head of the line
    $Host.UI.RawUI.CursorPosition = $currPosition
}

#### WAITS ####

function Start-SimpleWait {
    # hide the console cursor
    [Console]::CursorVisible = $false
    
    # controls how many dots to print
    $count = 1
    $char = '.'

    # loop until a key is pressed
    while (-not [Console]::KeyAvailable) {
        # write a new dot
        Write-Host $char -NoNewline

        # sleep to prevent the dots from looping too fast
        Start-Sleep -Milliseconds 750

        # increase the number of dots
        $count++

        # start over when 3 dots have printed
        if ($count -gt 3) {
            $count = 1
            Clear-CurrentLine
        }
    }

    # read key or the next call will fail
    $null = [Console]::ReadKey()

    # return the console back to normal
    Clear-CurrentLine
    [Console]::CursorVisible = $true
}

<###DEMO-BREAK###>

function Start-FancyBouncyWait {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Text = "(N)ext, (b)ack, (q)uit"
    )
    # fancy wait routine

    # controls the animation speed by spacing out the next "frame"
    # value is in miliseconds, lower number makes the animation faster, and vice versa
    # recommended: 75
    $animationDelayMs = 75

    # get the original foreground color
    $ogColor = $Host.UI.RawUI.ForegroundColor

    # the text layer
    $txtLen = $text.Length

    #region BOUNCE
    # the bounce: ╲, │, ╱
    [string[]]$bounce = '╲', '│', '╱'

    # the char that ties the bounce together: ━
    $bounceSep = [char]0x2501

    # the boundry shape: ║
    $boundry = [char]0x2551

    # turn the cursor off
    [System.Console]::CursorVisible = $false

    # calc the number of cycles
    $cycleLen = $bounce.Length + 1
    $numCycles = $txtLen / $cycleLen
    if ( ($numCycles * $cycleLen - 1) -lt $txtLen ) { $numCycles++ }

    # length of the bounce field
    $theFullBounce = ''
    for ($i = 0; $i -lt $numCycles; $i++) {
        for ($j = 0; $j -lt $bounce.Count; $j++) {
            $theFullBounce = [string]::Concat($theFullBounce, $bounce[$j])
        }

        if ($i -lt ($numCycles - 1) ) {
            $theFullBounce = [string]::Concat($theFullBounce, $bounceSep)
        }
    }
    $bounceLen = $theFullBounce.Length

    # not pad the text in case they are different lengths
    $text = $text.PadRight(($txtLen + $cycleLen), " ")
    $txtLen = $text.Length

    # bounce position
    $bouncePos = 0

    # original encoding
    $ogEncoding = [System.Console]::OutputEncoding

    # force UTF-8 encoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    Write-Host "`n"

    # what direction is the bounce: (r)ight or (l)eft
    $direction = 'r'

    # get start position
    $startPos = $Host.UI.RawUI.CursorPosition

    # write the start boundry
    [System.Console]::Write($boundry)

    # get current position
    $curPos = $Host.UI.RawUI.CursorPosition

    # get the end positions
    $endPos = $startPos
    $endPos.X = $curPos.X + $bounceLen

    #endregion

    # primary color used by the bounce
    $priColor = "[38;2;255;255;255m"

    # the fading colors
    $fadeColors = "[38;2;25;25;25m", "[38;2;55;55;55m", "[38;2;95;95;95m", "[38;2;135;135;135m", "[38;2;165;165;165m", "[38;2;195;195;195m", "[38;2;225;225;225m", "[38;2;255;255;255m"
    $fadeLen = $fadeColors.Count


    # fade tracker for start boundry
    $startFade = $fadeLen

    # fade tracker for start boundry
    $endFade = 0

    $command = 'r'
    $quit = $false

    # start the bounce
    do {
        # print the start boundry
        if ($startFade -ge 0) {
            $Host.UI.RawUI.CursorPosition = $startPos
            [System.Console]::Write("`e$($fadeColors[$startFade])$boundry")
            $startFade--
        } elseif ($endFade -ge 0) {
            $Host.UI.RawUI.CursorPosition = $endPos
            [System.Console]::Write("`e$($fadeColors[$endFade])$boundry")
            $endFade--
        }

        # move to the previous position
        $Host.UI.RawUI.CursorPosition = $curPos

        # do directional stuff
        switch ($direction) {
            'r' {
                # build the string
                $str = ""

                for ($i = 0; $i -lt $bounceLen; $i++) {
                    if ($i -eq $bouncePos) {
                        $str = [string]::Concat($str, "`e$priColor$($theFullBounce[$bouncePos])")
                    # add faded characters
                    } elseif ($i -eq ($bouncePos - 1)) { 
                        $char = $text[($bouncePos - 1)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 1)])$char")
                    } elseif ($i -eq ($bouncePos - 2)) { 
                        $char = $text[($bouncePos - 2)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 2)])$char")
                    } elseif ($i -eq ($bouncePos - 3)) { 
                        $char = $text[($bouncePos - 3)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 3)])$char")
                    } elseif ($i -eq ($bouncePos - 4)) { 
                        $char = $text[($bouncePos - 4)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 4)])$char")
                    } elseif ($i -eq ($bouncePos - 5)) { 
                        $char = $text[($bouncePos - 5)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 5)])$char")
                    } elseif ($i -eq ($bouncePos - 6)) { 
                        $char = $text[($bouncePos - 6)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 6)])$char")
                    } elseif ($i -eq ($bouncePos - 7)) { 
                        $char = $text[($bouncePos - 7)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 7)])$char")
                    } elseif ($i -eq ($bouncePos - 8)) { 
                        $char = $text[($bouncePos - 8)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 8)])$char")
                    } else {
                        $str = [string]::Concat($str, " ")
                    }
                }

                # increment position
                $bouncePos++

                # change direction when the end of line is reached
                if ($bouncePos -gt $bounceLen) {
                    $direction = 'l'
                    $bouncePos = $bounceLen
                    $endFade = $fadeLen
                    [System.Console]::Write("`e$($fadeColors[$endFade])$boundry")
                }
            }

            'l' {
                # build the string
                $str = ""

                for ($i = 0; $i -lt $bounceLen; $i++) {
                    if ($i -eq $bouncePos) {
                        $str = [string]::Concat($str, "`e$priColor$($theFullBounce[$bouncePos])")
                    # Create the first fade char
                    } elseif ($i -eq ($bouncePos + 1)) { 
                        $char = $text[($bouncePos + 1)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 1)])$char")
                    } elseif ($i -eq ($bouncePos + 2)) { 
                        $char = $text[($bouncePos + 2)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 2)])$char")
                    } elseif ($i -eq ($bouncePos + 3)) { 
                        $char = $text[($bouncePos + 3)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 3)])$char")
                    } elseif ($i -eq ($bouncePos + 4)) { 
                        $char = $text[($bouncePos + 4)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 4)])$char")
                    } elseif ($i -eq ($bouncePos + 5)) { 
                        $char = $text[($bouncePos + 5)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 5)])$char")
                    } elseif ($i -eq ($bouncePos + 6)) { 
                        $char = $text[($bouncePos + 6)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 6)])$char")
                    } elseif ($i -eq ($bouncePos + 7)) { 
                        $char = $text[($bouncePos + 7)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 7)])$char")
                    } elseif ($i -eq ($bouncePos + 8)) { 
                        $char = $text[($bouncePos + 8)]
                        $str = [string]::Concat($str, "`e$($fadeColors[($fadeLen - 8)])$char")
                    } else {
                        $str = [string]::Concat($str, " ")
                    }
                }

                # increment position
                $bouncePos--

                # change direction when the end of line is reached
                if ($bouncePos -lt 0) {
                    $direction = 'r'
                    $bouncePos = 0
                    $startFade = $fadeLen
                    [System.Console]::Write("`e$($fadeColors[$startFade])$boundry")
                }
            }
        }

        # write the line
        [System.Console]::Write($str)

        # the animation pause
        Start-Sleep -Milliseconds $animationDelayMs

        # check for a key press
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'Enter' {
                    $command = 'n'
                    $quit = $true
                    break
                }
                'n' {
                    $command = 'n'
                    $quit = $true
                    break
                }
                'b' {
                    $command = 'b'
                    $quit = $true
                    break
                }
                'q' {
                    $command = 'q'
                    $quit = $true
                    break
                }
                default {
                    # ignore the key press
                    #Write-Host $key.Key
                }
            }
        }
    } until ($quit)

    # clear the line
    $Host.UI.RawUI.CursorPosition = $startPos
    $cll = "".PadRight(($bounceLen + $cycleLen), " ")
    [System.Console]::Write("$cll`n")
    $Host.UI.RawUI.ForegroundColor = $ogColor

    # move back up
    $Host.UI.RawUI.CursorPosition = $curPos

    # reset encoding 
    [System.Console]::OutputEncoding = $ogEncoding
    [System.Console]::CursorVisible = $true

    return $command
}

<###DEMO-BREAK###>

#region type accelerators
# add type accelerators so the classes will export with Import-Module
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7.4#exporting-classes-with-type-accelerators

# Define the types to export with type accelerators.
$ExportableTypes =@(
    [DemoQuoteType]
    [DemoApprovedVerbs]
    [DemoApprovedVerbsFirstLetter]
    [DemoLineColoring]
    [DemoLineType]
    [DemoType]
    [DemoHighlightColor]
    [DemoColor]
    [DemoHighlightPowerShell]
    [DemoLine]
    [DemoSegment]
    [Demo]
)

# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)

# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
foreach ($Type in $ExportableTypes) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        # silently throw a message to the verbose stream
        Write-Verbose @"
Unable to register type accelerator[$($Type.FullName)]. The Accelerator already exists.
"@

    }
}

# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}

# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()
#endregion type accelerators