function getAdapterDetails ($interface) {
    # Get index of selected interface to be used to query interface settings
    $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object interfaceindex
    $intDetails = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object IPEnabled | Where-Object interfaceindex -eq $intIndex.interfaceindex | Select-Object ipaddress, ipsubnet, defaultipgateway, dnsserversearchorder
    
    # If the program closes before a static ip is set, it will pull ipv6 or 169.x.x.x
    # If this is the case, set the adapter back to dhcp. This is currently a bit bugged.
    # It won't populate the text boxes with the correct DHCP address but if you refresh the adapters, it reloads the data correctly.
    if (($intDetails.ipaddress[0]) -Match "169" -or ($intDetails.ipaddress[0]) -Match "fe80") {
        setMode $selectAdapter.SelectedItem "DHCP"
        
        # checkAdapters
    } else {
        $ipaddressTxt.Text = $intDetails.ipaddress[0]
        $subnetMaskTxt.Text = $intDetails.ipsubnet[0]
    }
    if ($intDetails.defaultipgateway.count -ne 0) {
        $gatewayTxt.Text = $intDetails.defaultipgateway[0]
    } else {
        $gatewayTxt.Clear()
    }
    if ($intDetails.dnsserversearchorder.count -ne 0) {
        $dnsTxt.Text = $intDetails.dnsserversearchorder[0]
    } else {
        $dnsTxt.Clear()
    }
 }