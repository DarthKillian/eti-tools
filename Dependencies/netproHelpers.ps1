function Convert-SubnetMaskToCIDR {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SubnetMask
    )

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
        throw "Subnet mask conversion failed. Binary mask must be all 1s followed by all 0s"
    }

    # Count the binary 1s in the array and present as the CIDR
    $cidr = ($binaryMask.ToCharArray() | Where-Object { $_ -eq '1' }).Count
    return $cidr
}
