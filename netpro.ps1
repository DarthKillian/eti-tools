Add-Type -AssemblyName PresentationFramework

# Load dependency path
$dependencyPath = "$($pwd)\Dependencies"

# Check for helper script then load it. If it is missing, throw an exception and gracefully exit
try {
   if (-Not (Test-Path $dependencyPath\netproHelpers.ps1)) {
      throw "netproHelpers.ps1 not found"
   }

   . "$dependencyPath\netproHelpers.ps1"
}
catch {
   [System.Windows.MessageBox]::Show("Missing core dependency:`n$($_.Exception.Message)", "Missing Dependency", "OK", "Error")
   exit
}
# Get-ChildItem -Path $dependencyPath -Filter *.ps1 | ForEach-Object {. $_.FullName }

# Set xaml path for window
$xamlPath = "$($pwd)\xaml\MainWindow.xaml"

# Check if xaml exists and read the file
if (Test-Path $xamlPath) {
   $loadXaml = Get-Content $xamlPath -Raw 
}

# Leaving this as an example for later implementation of running pings directly
# Start-Process cmd -ArgumentList {/c "ping google.com -t"}

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
$noAdapters = $window.FindName("noAdapters")
$saveStaticBtn = $window.FindName("saveStaticBtn")
$addNewIPBtn = $window.FindName("addNewIPBtn")

# Get text boxes
$ipaddressTxt = $window.FindName("ipaddress")
$subnetMaskTxt = $window.FindName("subnet_mask")
$gatewayTxt = $window.FindName("gateway")
$dnsTxt = $window.FindName("dns")

# Check if the adapter mode is dhcp or static
function checkMode ($interface) {
   try {
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
   catch {
      [System.Windows.MessageBox]::Show("Unexpected error in checkMode:`n$($_.Exception.Message)", "Unhandled Exception", "OK", "Error")
   }
   
}

# Get all physiscal adpaters
# Now iterate through them and only get the adapters that are up then assign them to the adapter select box
function checkAdapters () {
   # Clear the listbox to make sure nothing funky exists before enumerating our items
   $selectAdapter.Items.Clear()

   try {
      # Query the adapters filtering on connected and no WiFi adapters
      $adapters = Get-CimInstance -Classname Win32_NetworkAdapter -Filter "NetConnectionStatus = 2" | Where-Object { $_.NetConnectionID -ne "Wi-Fi" }

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

# Load the details of the adapters in the text boxes
function loadInterfaceDetails ($interface) {
   $adapterDetails = getAdapterDetails $interface
   $ipaddressTxt.Text = $adapterDetails.ip
   $subnetMaskTxt.Text = $adapterDetails.mask
   if ($adapterDetails.gateway.count -ne 0) {
      $gatewayTxt.Text = $adapterDetails.gateway
   }
   else {
      $gatewayTxt.Clear()
   }
   if ($adapterDetails.dns.count -ne 0) {
      $dnsTxt.Text = $adapterDetails.dns
   }
   else {
      $dnsTxt.Clear()
   }
}

function setStaticIP {
   Param($interface, $ip, $subnet, $gateway, $dns)
   $ipParams = @{
      Interface = $interface
   }

   try {
      if ($ip -and $subnet) {
         try {
            [ipaddress] $ip | Out-Null
            [ipaddress] $subnet | Out-Null

            $ipParams['IPAddress'] = $ip
            $ipParams['Subnet'] = $subnet

            # Lookup current IP and see if it is being changed
            $oldIP = getAdapterDetails $interface

         }
         catch {
            throw "Invalid IP Address or Subnet Mask. Please verify that you have entered a proper IPV4 IP Address and Subnet Mask."
            return
         }
         
      }
      else {
         throw "IP and Subnet Mask are required"
      }
   }
   catch {
      [System.Windows.MessageBox]::Show("Invalid entry:`n$($_.Exception.Message)", "Invalid Entry", "OK", "Error")
   }

   # If a gateway is provided, set the gateway
   if ($gateway) {
      try {
         [ipaddress] $gateway | Out-Null
         $ipCmd = netsh int ip set address "$($interface)" static $ip $subnet $gateway
      }
      catch {
         $message = "Invalid gateway"
         [System.Windows.MessageBox]::Show($message, "Warning", "OK")
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
   try {
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
         loadInterfaceDetails $interface
      }
   }
   catch {
      [System.Windows.MessageBox]::Show("Unexpected error in setMode:`n$($_.Exception.Message)", "Unhandled Exception", "OK", "Error")
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
         loadInterfaceDetails $selectAdapter.SelectedItem
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