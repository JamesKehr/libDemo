
#requires -Version 5.1
#requires -Modules NetTCPIP

using namespace System.Collections.Generic

[CmdletBinding()]
param (
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [ValidateRange(1,1024)]
    [int]
    $Index
)

begin {
    # stores details about an individual NIC
    class NetworkAdapter {
        [string]
        $Name

        [string]
        $Description

        [int]
        $Index

        [CimInstance]
        $NetAdapter

        [CimInstance]
        $IpInterfaceV4

        [CimInstance]
        $IpInterfaceV6

        [CimInstance]
        $Bindings

        NetworkAdapter([int]$idx) {
            Write-Verbose "[NetworkAdapter] - ValidateByIndex"
            $this.ValidateByIndex($idx)
            Write-Verbose "[NetworkAdapter].ValidateByIndex - Work completed successfully."
        }

        ValidateByIndex($idx) {
            $validIdx = Get-NetAdapter -InterfaceIndex $idx -ErrorAction SilentlyContinue
            Write-Verbose "[NetworkAdapter].ValidateByIndex - validIdx: $($validIdx.Name)"

            if ($validIdx) {
                Write-Verbose "[NetworkAdapter].ValidateByIndex - Adapter found!"
                Write-Verbose "[NetworkAdapter].ValidateByIndex - Updating properties."
                $this.NetAdapter  = $validIdx
                $this.Description = $validIdx.InterfaceDescription
                $this.Name        = $validIdx.Name
                $this.Index       = $idx

                Write-Verbose "[NetworkAdapter].ValidateByIndex - Getting the IP interfaces."
                $ipInt4 = Get-NetIPInterface -InterfaceIndex $idx -AddressFamily IPv4 -EA SilentlyContinue
                $ipInt6 = Get-NetIPInterface -InterfaceIndex $idx -AddressFamily IPv6 -EA SilentlyContinue

                Write-Debug "[NetworkAdapter].ValidateByIndex - Adding IP interfaces."
                $this.IpInterfaceV4 = $ipInt4
                $this.IpInterfaceV6 = $ipInt6
            } else {
                throw "Failed to find a network adapter at index $idx."
            }
        }

        [bool]
        IsEthernet() {
            Write-Debug "[NetworkAdapter].IsEthernet - Begin"
            if ($this.NetAdapter.NdisPhysicalMedium -eq 14) {
                Write-Debug "[NetworkAdapter].IsEthernet - true"
                return $true
            } else {
                Write-Debug "[NetworkAdapter].IsEthernet - false"
                return $false
            }
        }
    }
<###DEMO-BREAK###>

    function Write-IsEthernet {
        [CmdletBinding()]
        param (
            [Parameter()]
            $List
        )

        foreach ($item in $list) {
            if ($item.IsEthernet()) {
                Write-Host -ForegroundColor Green "$($item.Name) is an Ethernet adapter."
            } else {
                Write-Host -ForegroundColor Yellow "$($item.Name) is not an Ethernet adapter."
            }
        }
    }
<###DEMO-BREAK###>

    # stores all the results
    $results = [List[NetworkAdapter]]::new()

}

process {
    Write-Verbose "process - Begin"
    Write-Verbose "process - Index: $Index"
    
    try {
        $tmpNA = [NetworkAdapter]::new($Index)

        $results.Add($tmpNA)
    } catch {
        return (Write-Error "Failed to parse a network adapter. Error: $_" -EA Stop)
    }
}
<###DEMO-BREAK###>

end {
    Write-IsEthernet $results
    return $results
}
