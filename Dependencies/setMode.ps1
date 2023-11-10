function setMode($interface, $mode) {
    if ($mode -eq "STATIC") {
        Set-NetIPInterface -InterfaceAlias $interface -Dhcp Disabled
        $dhcpOption.IsChecked = $false
        $ipaddressTxt.IsReadOnly = $false
        $subnetMaskTxt.IsReadOnly = $false
        $gatewayTxt.IsReadOnly = $false
        $dnsTxt.IsReadOnly = $false
        $ipaddressTxt.Clear()
        $subnetMaskTxt.Clear()
        $gatewayTxt.Clear()
        $dnsTxt.Clear()
        $subnetMaskTxt.Text = "255.255.255.0"
    }

    if ($mode -eq "DHCP") {
        Set-NetIPInterface -InterfaceAlias $interface -Dhcp Enabled
        # The checkmode does this already but it hangs the script trying to check the mode so for now, I'm manually setting these here
        $dhcpOption.IsChecked = $true
        $ipaddressTxt.IsReadOnly = $true
        $subnetMaskTxt.IsReadOnly = $true
        $gatewayTxt.IsReadOnly = $true
        $dnsTxt.IsReadOnly = $true
        getAdapterDetails $interface
    }
    
}