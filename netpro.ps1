Add-Type -AssemblyName PresentationFramework

# Load dependencies
<# $dependencyPath = "$($pwd)\Dependencies"
Get-ChildItem -Path $dependencyPath -Filter *.ps1 | ForEach-Object {. $_.FullName } #>

# Set xaml path for window
$xamlPath = "$($pwd)\xaml\MainWindow.xaml"

# Check if xaml exists and read the file
if (Test-Path $xamlPath) {
   $loadXaml = Get-Content $xamlPath -Raw 
}

# Load xaml
[xml]$xaml = $loadXaml
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$selectAdapter = $window.FindName("selectAdapter")
$dhcpOption = $window.FindName("dhcpOption")
$staticOption = $window.FindName("staticOption")
$reloadBtn = $window.FindName("reload")
$staticButtons = $window.FindName("staticButtons")
$adapterOptions = $window.FindName("adapterOptions")
$noAdapters = $window.findName("noAdapters")
$saveStaticBtn = $window.findName("saveStaticBtn")
$addNewIPBtn = $window.FindName("addNewIPBtn")

# Get text boxes
$ipaddressTxt = $window.FindName("ipaddress")
$subnetMaskTxt = $window.FindName("subnet_mask")
$gatewayTxt = $window.FindName("gateway")
$dnsTxt = $window.FindName("dns")

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
      $staticButtons.Visibility = "Hidden"
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

# Get all physiscal adpaters
# Now iterate through them and only get the adapters that are up then assign them to the adapter select box
function checkAdapters () {
   # Clear the listbox to make sure nothing funky exists before enumerating our items
   $selectAdapter.Items.Clear()

   try {
      # Query the adapters filtering on connected and no WiFi adapters
      $adapters = Get-CimInstance -Classname Win32_NetworkAdapter -Filter "NetConnectionStatus = 2" | Where-Object {$_.NetConnectionID -ne "Wi-Fi" }

      foreach ($adapter in $adapters) {
         $selectAdapter.Items.Add($adapter.netconnectionid) | Out-Null
      }

      # Select the first adapter in the list and focus on the selection box
      $selectAdapter.SelectedIndex = 0
      $selectAdapter.Focus() | Out-Null
   }
   catch [Microsoft.Management.Infrastructure.CimException] {
      [System.Windows.MessageBox]::Show("CIM error while retrieving network adapters:`n$($_.Exception.Message)", "CIM Error", "OK", "Error")
   }
   catch {
      [System.Windows.MessageBox]::Show("Unexpected error in checkAdapters:`n$($_.Exception.Message)", "Unhandled Exception", "OK", "Error")
   }
}

# Get details of the adapters
function getAdapterDetails ($interface) {
   # Get index of selected interface to be used to query interface settings
   $intIndex = Get-NetIPConfiguration -InterfaceAlias $interface | Select-Object interfaceindex
   $intDetails = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object IPEnabled | Where-Object interfaceindex -eq $intIndex.interfaceindex | Select-Object ipaddress, ipsubnet, defaultipgateway, dnsserversearchorder
   
   $ipaddressTxt.Text = $intDetails.ipaddress[0]
   $subnetMaskTxt.Text = $intDetails.ipsubnet[0]
   if ($intDetails.defaultipgateway.count -ne 0) {
      $gatewayTxt.Text = $intDetails.defaultipgateway[0]
   }
   else {
      $gatewayTxt.Clear()
   }
   if ($intDetails.dnsserversearchorder.count -ne 0) {
      $dnsTxt.Text = $intDetails.dnsserversearchorder[0]
   }
   else {
      $dnsTxt.Clear()
   }
}

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

      $ipCmd = netsh int ip set address "$($interface)" static $ip $subnet

   }
   else {
      $message = "IP Address and Subnet Mask are required"
   }
   # If a gateway is provided, set the gateway
   if ($gateway) {
      try {
         [ipaddress] $gateway | Out-Null
         $ipCmd = netsh int ip set address "$($interface)" static $ip $subnet $gateway
      }
      catch {
         $message = "Invalid gateway"
         [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
      }
   }
   else {
      $ipCmd = netsh int ipv4 set address "$($interface)" static $ip $subnet
   }

   # Set Static IP
   & cmd.exe /c $ipCmd
   if ($LASTEXITCODE -ne 0) {
      [System.Windows.MessageBox]::Show("There was an error setting the IP address on $interface. Please report this bug.", "Warning", $ButtonType)
   }
    
   if ($dns) {
      try {
         [ipaddress] $dns | Out-Null
         & cmd.exe /c netsh int ipv4 set dnsservers "$($interface)" static $dns primary
      }
      catch {
         $message = "Invalid DNS"
         [System.Windows.MessageBox]::Show($message, "Warning", $ButtonType)
      }
   }
   else {
      & cmd.exe /c netsh int ipv4 delete dnsservers "$($interface)" all
   }
}

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

if ($selectAdapter.Items.Count -ne 0) {
   $noAdapters.Visibility = "Hidden"
   $adapterOptions.Visibility = "Visible"
}
else {
   $noAdapters.Visibility = "Visible"
   $adapterOptions.Visibility = "Hidden"
}

# Listen for selectAdapter selection change event.
$selectAdapter.Add_SelectionChanged({
      if ($selectAdapter.Items.Count -ne 0) {
         checkMode $selectAdapter.SelectedItem
         getAdapterDetails $selectAdapter.SelectedItem
         $noAdapters.Visibility = "Hidden"
         $adapterOptions.Visibility = "Visible"
      }
      else {
         $noAdapters.Visibility = "Visible"
         $adapterOptions.Visibility = "Hidden"
      }
   })

$dhcpOption.Add_Click({
      setMode $selectAdapter.SelectedItem "DHCP"
      $staticButtons.Visibility = "Hidden"
   })

$staticOption.Add_Click({
      setMode $selectAdapter.SelectedItem "STATIC"
      $staticButtons.Visibility = "Visible"
   })

$saveStaticBtn.Add_Click({
      setStaticIP $selectAdapter.SelectedItem $ipaddressTxt.Text $subnetMaskTxt.Text $gatewayTxt.Text $dnsTxt.Text
   })
# $addIP = . ".\Dependencies\addIP.ps1"
$addNewIPBtn.Add_Click({
   . '.\Dependencies\addIP.ps1'
   })

# Reload the adapters after reload button click
$reloadBtn.Add_Click({ checkAdapters })
checkAdapters # Run the checkAdapters function

$window.ShowDialog() | Out-Null