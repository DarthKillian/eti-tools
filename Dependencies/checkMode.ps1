# Check if the adapter mode is dhcp or static
function checkMode ($interface) {
    # Write-Host Inside checkMode
    $mode = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object -ExpandProperty NetIPv4Interface | Select-Object dhcp
    if ($mode.dhcp -eq "Enabled") {
       $dhcpOption.IsChecked = $true
       $ipaddressTxt.IsReadOnly = $true
       $subnetMaskTxt.IsReadOnly = $true
       $gatewayTxt.IsReadOnly = $true
       $dnsTxt.IsReadOnly = $true
    }
    else {
       $staticOption.IsChecked = $true
       $dhcpOption.IsChecked = $false
       $ipaddressTxt.IsReadOnly = $false
       $subnetMaskTxt.IsReadOnly = $false
       $gatewayTxt.IsReadOnly = $false
       $dnsTxt.IsReadOnly = $false
       $staticButtons.Visibility = "Visible"

    }
 }