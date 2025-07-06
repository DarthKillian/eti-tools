function Convert-SubnetMaskToCIDR {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SubnetMask
    )

    try {
        # Sanitize user input and verify that the input is a valid ipv4 format
        if (-not ($SubnetMask -match '^(\d{1,3}\.){3}\d{1,3}$')) {
            throw "Invalid subnet mask format"
        }

        # Split the octets on the . then iterate through the octets to verify the octets are valid subnet octets
        $octets = $SubnetMask -split '\.'
        foreach ($octet in $octets) {
            if ([int]$octet -lt 0 -or [int]$octet -gt 255) {
                throw "Invalid octet in subnet mask: $octet"
            }
        }

        # Convert octets to binary
        $binaryMask = ($octets | ForEach-Object {
                [Convert]::ToString([int]$_, 2).PadLeft(8, '0')
            }) -join ''

        # Check if valid binary
        if ($binaryMask -match '01.*1') {
            throw "You entered $SubnetMask. Please change it to a correct Subnet Mask format."
        }

        # Count the binary 1s in the array and present as the CIDR
        $cidr = ($binaryMask.ToCharArray() | Where-Object { $_ -eq '1' }).Count
        return $cidr
    }
    catch {
        [System.Windows.MessageBox]::Show("Subnet Mask invalid:`n$($_.Exception.Message)", "Invalid Subnet Mask", "OK", "Error")
    }
}

# Get details of the adapters
function getAdapterDetails ($interface) {
    [Parameter(Mandatory = $true)]
    [string] $interface
    
    # Try and get the details of the adapter that is selected
    try {
        # Get the index of the interface
        $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object InterfaceIndex
        # Here is where we get the actual details of the interface using the index of the interface
        $intDetails = Get-CimInstance -Classname Win32_NetworkAdapterConfiguration | Where-Object IPEnabled | Where-Object InterfaceIndex -eq $intIndex.InterfaceIndex | Select-Object ipaddress, ipsubnet, defaultipgateway, dnsserversearchorder

        if ($intDetails) {
            # Only load the ip address and subnet in the hash table to start with
            [hashtable]$details = @{ 'ip' = $intDetails.ipaddress[0]; 'mask' = $intDetails.ipsubnet[0] }

            # Default gateway present? Load it into the hash table
            if ($intDetails.defaultipgateway) {
                $details.Add('gateway', $intDetails.defaultipgateway[0])
            }

            # DNS present? Load it into the hash table
            if ($intDetails.dnsserversearchorder) {
                $details.Add('dns', $intDetails.dnsserversearchorder[0])
            }

            return $details
        }
    }
    catch [Microsoft.Management.Infrastructure.CimException] {
        [System.Windows.MessageBox]::Show("CIM error while retrieving network adapter details:`n$($_.Exception.Message)", "CIM Error", "OK", "Error")
    }
    catch {
        [System.Windows.MessageBox]::Show("Unexpected error in getAdapterDetails:`n$($_.Exception.Message)", "Unhandled Exception", "OK", "Error")
    }
}

function Test-IPExists {
    param (
        [Parameter(Mandatory = $true)]
        [string] $interface,
        [string] $ip
    )
    # Check if the IP exists we have already validated the input before passing to this helper function so we don't need to do it here
    $existingIP = Get-NetIPAddress -InterfaceAlias $interface -IPAddress $ip -ErrorAction SilentlyContinue
    return [bool]$existingIP
}
