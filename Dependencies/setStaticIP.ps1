$ButtonType = [System.Windows.MessageBoxButton]::Ok

function setStaticIP {
    Param($interface, $ip, $subnet, $gateway, $dns)

    if ($ip -and $subnet) {
        try {
            [ipaddress] $ip | Out-Null
            [ipaddress] $subnet | Out-Null
        }
        catch {
            $message = "Invalid IP or Subnet Mask"
        }

        $ipCmd = "netsh int ip set address $interface static $ip $subnet"

    }
    else {
        $message = "IP Address and Subnet Mask are required"
    }
    # If a gateway is provided, set the gateway
    if ($gateway) {
        try {
            [ipaddress] $gateway | Out-Null
           $ipCmd = $ipCmd + " $gateway"
        }
        catch {
            $message = "Invalid gateway"
            [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
        }
    } else {
        $ipCmd = "netsh int ip set address $interface static $ip $subnet"
    }
    # Set Static IP
    & cmd.exe /c $ipCmd
    if ($LASTEXITCODE -ne 0) {
        [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
    }
    
    if ($dns) {
        try {
            [ipaddress] $dns | Out-Null
            & cmd.exe /c "netsh int ipv4 set dnsservers $interface static $dns primary"
        }
        catch {
            $message = "Invalid DNS"
            [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
        }
    } else {
        & cmd.exe /c "netsh int ipv4 delete dnsservers $interface all"
    }

    
}