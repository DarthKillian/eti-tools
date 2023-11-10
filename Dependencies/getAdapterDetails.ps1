function getAdapterDetails ($interface) {
    # Get index of selected interface to be used to query interface settings
    $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object interfaceindex
    $intDetails = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object IPEnabled | Where-Object interfaceindex -eq $intIndex.interfaceindex | Select-Object ipaddress, ipsubnet, defaultipgateway, dnsserversearchorder
    $ipaddressTxt.Text = $intDetails.ipaddress[0]
    $subnetMaskTxt.Text = $intDetails.ipsubnet[0]
    $gatewayTxt.Text = $intDetails.defaultipgateway[0]
    $dnsTxt.Text = $intDetails.dnsserversearchorder[0]
 }